import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface PushNotifyPayload {
  message_id: string;
  conversation_id: string;
  sender_id: string;
  sender_name: string;
  title?: string;
  body: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: corsHeaders }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const { createClient } = await import("npm:@supabase/supabase-js@2");
    const supabase = createClient(supabaseUrl, supabaseKey);

    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid token" }),
        { status: 401, headers: corsHeaders }
      );
    }

    const payload: PushNotifyPayload = await req.json();

    if (!payload.conversation_id || !payload.message_id) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields: conversation_id, message_id",
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    const { data: participants, error: participantError } = await supabase
      .from("conversation_participants")
      .select("user_id")
      .eq("conversation_id", payload.conversation_id)
      .neq("user_id", user.id);

    if (participantError) {
      console.error("Error fetching participants:", participantError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch participants" }),
        { status: 500, headers: corsHeaders }
      );
    }

    if (!participants || participants.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message_id: payload.message_id,
          notifications_sent: 0,
          recipients: [],
        }),
        { status: 200, headers: corsHeaders }
      );
    }

    const recipientUserIds = participants.map((p) => p.user_id);

    const { data: devices, error: deviceError } = await supabase
      .from("profile_devices")
      .select("user_id, fcm_token, platform")
      .in("user_id", recipientUserIds)
      .gt("last_seen", new Date(Date.now() - 1000 * 60 * 60).toISOString());

    if (deviceError) {
      console.error("Error fetching devices:", deviceError);
    }

    const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID");
    const firebasePrivateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");
    const firebaseClientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");

    if (!firebaseProjectId || !firebasePrivateKey || !firebaseClientEmail) {
      console.warn("Firebase not configured - skipping notifications");
      return new Response(
        JSON.stringify({
          success: true,
          message_id: payload.message_id,
          notifications_sent: 0,
          recipients: [],
          warning: "Firebase not configured",
        }),
        { status: 200, headers: corsHeaders }
      );
    }

    const devicesByUser = new Map<string, Array<{ fcm_token: string; platform: string }>>();
    (devices || []).forEach((device) => {
      if (!devicesByUser.has(device.user_id)) {
        devicesByUser.set(device.user_id, []);
      }
      devicesByUser.get(device.user_id)!.push({
        fcm_token: device.fcm_token,
        platform: device.platform,
      });
    });

    let totalNotificationsSent = 0;
    const recipientsSummary: Array<{ user_id: string; device_count: number; success: boolean }> = [];

    const accessToken = await getFirebaseAccessToken(
      firebaseClientEmail,
      firebasePrivateKey
    );

    for (const [userId, userDevices] of devicesByUser.entries()) {
      let successCount = 0;

      for (const device of userDevices) {
        try {
          const fcmMessage = {
            message: {
              token: device.fcm_token,
              notification: {
                title: payload.title || `${payload.sender_name}`,
                body: payload.body,
              },
              data: {
                conversation_id: payload.conversation_id,
                message_id: payload.message_id,
                sender_id: payload.sender_id,
                sender_name: payload.sender_name,
                message_body: payload.body,
              },
              android: {
                priority: "high",
                notification: {
                  sound: "default",
                  click_action: "FLUTTER_NOTIFICATION_CLICK",
                  channel_id: "messages",
                },
              },
              apns: {
                payload: {
                  aps: {
                    alert: {
                      title: payload.title || `${payload.sender_name}`,
                      body: payload.body,
                    },
                    sound: "default",
                    badge: 1,
                  },
                },
              },
            },
          };

          const fcmResponse = await fetch(
            `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
            {
              method: "POST",
              headers: {
                "Authorization": `Bearer ${accessToken}`,
                "Content-Type": "application/json",
              },
              body: JSON.stringify(fcmMessage),
            }
          );

          if (fcmResponse.ok) {
            successCount++;
            totalNotificationsSent++;
            console.log(`Notification sent successfully to ${device.fcm_token}`);
          } else {
            const errorData = await fcmResponse.text();
            console.error(
              `Failed to send notification to ${device.fcm_token}: ${errorData}`
            );

            if (errorData.includes("UNREGISTERED") || errorData.includes("INVALID_ARGUMENT")) {
              await supabase
                .from("profile_devices")
                .delete()
                .eq("fcm_token", device.fcm_token);
              console.log(`Removed invalid/unregistered token: ${device.fcm_token}`);
            }
          }
        } catch (error) {
          console.error(
            `Error sending notification to ${device.fcm_token}:`,
            error
          );
        }
      }

      recipientsSummary.push({
        user_id: userId,
        device_count: userDevices.length,
        success: successCount > 0,
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        message_id: payload.message_id,
        notifications_sent: totalNotificationsSent,
        recipients: recipientsSummary,
      }),
      {
        status: 200,
        headers: corsHeaders,
      }
    );
  } catch (error) {
    console.error("Error in push_notify:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: error.message }),
      { status: 500, headers: corsHeaders }
    );
  }
});

async function getFirebaseAccessToken(
  clientEmail: string,
  privateKey: string
): Promise<string> {
  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const unsignedToken = `${encodedHeader}.${encodedPayload}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsignedToken)
  );

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
  const signedToken = `${unsignedToken}.${encodedSignature}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: signedToken,
    }),
  });

  const data = await response.json();
  return data.access_token;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const pemContents = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\\n/g, "")
    .replace(/\s/g, "");

  const binaryString = atob(pemContents);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}

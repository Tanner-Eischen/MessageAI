// @ts-nocheck - Deno Edge Function (disable all TypeScript checks for VS Code)
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

interface PushNotifyPayload {
  message_id: string;
  conversation_id: string;
  sender_id: string;
  sender_name: string;
  title: string;
  body: string;
}

interface PushNotifyResponse {
  success: boolean;
  message_id: string;
  notifications_sent: number;
  recipients: Array<{
    user_id: string;
    device_count: number;
  }>;
}

interface ErrorResponse {
  error: string;
  status: number;
}

// CORS headers
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

// Helper function to generate Firebase OAuth2 access token
async function getFirebaseAccessToken(
  privateKey: string,
  clientEmail: string
): Promise<string> {
  const jwtHeader = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  
  const now = Math.floor(Date.now() / 1000);
  const jwtClaimSet = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };
  const jwtClaimSetEncoded = btoa(JSON.stringify(jwtClaimSet));
  
  // Import private key
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = privateKey
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\\n/g, "")
    .replace(/\s/g, "");
  
  const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));
  
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
  
  // Sign JWT
  const signatureInput = `${jwtHeader}.${jwtClaimSetEncoded}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signatureInput)
  );
  
  const signatureBase64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
  
  const jwt = `${signatureInput}.${signatureBase64}`;
  
  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  
  if (!tokenResponse.ok) {
    throw new Error(`Failed to get access token: ${await tokenResponse.text()}`);
  }
  
  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

serve(async (req) => {
  console.log("🔔 Push notify function called");
  
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get authenticated user
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      console.error("❌ No authorization header");
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: corsHeaders }
      );
    }

    // Create Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get user ID from JWT token
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

    // Parse request body
    const payload: PushNotifyPayload = await req.json();
    console.log("📬 Payload received:", { 
      message_id: payload.message_id,
      conversation_id: payload.conversation_id,
      sender_id: payload.sender_id 
    });

    // Validate required fields
    if (!payload.conversation_id || !payload.message_id) {
      console.error("❌ Missing required fields");
      return new Response(
        JSON.stringify({
          error: "Missing required fields: conversation_id, message_id",
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Get all conversation participants
    console.log("👥 Fetching conversation participants...");
    const { data: participants, error: participantError } = await supabase
      .from("conversation_participants")
      .select("user_id")
      .eq("conversation_id", payload.conversation_id)
      .neq("user_id", user.id); // Exclude sender

    if (participantError) {
      console.error("Error fetching participants:", participantError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch participants" }),
        { status: 500, headers: corsHeaders }
      );
    }

    if (!participants || participants.length === 0) {
      console.log("ℹ️ No other participants to notify");
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
    console.log(`📱 Found ${recipientUserIds.length} recipient(s):`, recipientUserIds);

    // Get all devices for participants
    // No timeout check - push notifications should work even if user hasn't opened app in days
    // FCM will handle invalid/uninstalled tokens automatically
    console.log(`📲 Fetching all devices for recipients...`);
    
    const { data: devices, error: deviceError } = await supabase
      .from("profile_devices")
      .select("user_id, fcm_token, platform, last_seen")
      .in("user_id", recipientUserIds);

    if (deviceError) {
      console.error("❌ Error fetching devices:", deviceError);
      // Continue without devices - not critical
    }
    
    console.log(`📲 Found ${devices?.length || 0} device(s)`);
    if (devices && devices.length > 0) {
      devices.forEach(d => {
        const daysSinceLastSeen = Math.floor((Date.now() - new Date(d.last_seen).getTime()) / (1000 * 60 * 60 * 24));
        console.log(`   - User: ${d.user_id}, Platform: ${d.platform}, Last seen: ${daysSinceLastSeen} days ago, Token: ${d.fcm_token.substring(0, 20)}...`);
      });
    } else {
      console.log("⚠️ No devices found! Check:");
      console.log(`   - Are recipient user_ids correct? ${recipientUserIds.join(', ')}`);
      console.log(`   - Are devices registered in profile_devices table?`);
    }

    // Group devices by user
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

    // Get Firebase credentials from environment
    const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID");
    const firebasePrivateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");
    const firebaseClientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");

    console.log("🔥 Firebase config check:", {
      projectId: firebaseProjectId ? "✅ Set" : "❌ Missing",
      privateKey: firebasePrivateKey ? "✅ Set" : "❌ Missing",
      clientEmail: firebaseClientEmail ? "✅ Set" : "❌ Missing"
    });

    // Check if Firebase is configured
    if (!firebaseProjectId || !firebasePrivateKey || !firebaseClientEmail) {
      console.warn("⚠️ Firebase not configured - skipping notifications");
      return new Response(
        JSON.stringify({
          success: true,
          message_id: payload.message_id,
          notifications_sent: 0,
          recipients: Array.from(devicesByUser.keys()).map((userId) => ({
            user_id: userId,
            device_count: devicesByUser.get(userId)?.length || 0,
          })),
        }),
        { status: 200, headers: corsHeaders }
      );
    }

    // Send notifications to each device
    console.log(`🚀 Sending notifications to ${devicesByUser.size} user(s)...`);
    let totalNotificationsSent = 0;
    const recipientsSummary: Array<{ user_id: string; device_count: number }> = [];

    for (const [userId, userDevices] of devicesByUser.entries()) {
      for (const device of userDevices) {
        try {
          console.log(`📤 Sending to ${device.platform}: ${device.fcm_token.substring(0, 20)}...`);
          
          // Prepare FCM message
          const fcmMessage = {
            message: {
              token: device.fcm_token,
              notification: {
                title: payload.title || "New message",
                body: payload.body || `${payload.sender_name} sent a message`,
              },
              data: {
                conversation_id: payload.conversation_id,
                message_id: payload.message_id,
                sender_id: payload.sender_id,
                sender_name: payload.sender_name,
              },
              // Android-specific
              android: {
                priority: "high",
                notification: {
                  sound: "default",
                  click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
              },
              // iOS-specific
              apns: {
                payload: {
                  aps: {
                    alert: {
                      title: payload.title || "New message",
                      body: payload.body || `${payload.sender_name} sent a message`,
                    },
                    sound: "default",
                    badge: 1,
                  },
                },
              },
            },
          };

          // Get OAuth2 access token for FCM
          console.log("🔑 Getting Firebase access token...");
          const accessToken = await getFirebaseAccessToken(
            firebasePrivateKey,
            firebaseClientEmail
          );
          console.log("✅ Got access token");

          // Call Firebase Cloud Messaging API
          console.log(`📡 Calling FCM API for project: ${firebaseProjectId}`);
          const fcmResponse = await fetch(
            `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
            {
              method: 'POST',
              headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify(fcmMessage),
            }
          );

          if (fcmResponse.ok) {
            totalNotificationsSent++;
            console.log(`✅ SUCCESS! Notification sent to ${device.platform} device`);
          } else {
            const errorText = await fcmResponse.text();
            console.error(`❌ FCM API error ${fcmResponse.status}: ${errorText}`);
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
      });
    }

    const response: PushNotifyResponse = {
      success: true,
      message_id: payload.message_id,
      notifications_sent: totalNotificationsSent,
      recipients: recipientsSummary,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: corsHeaders,
    });
  } catch (error) {
    console.error("Error in push_notify:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: corsHeaders }
    );
  }
});

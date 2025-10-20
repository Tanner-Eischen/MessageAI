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

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get authenticated user
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
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

    // Validate required fields
    if (!payload.conversation_id || !payload.message_id) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields: conversation_id, message_id",
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Get all conversation participants
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
      // No other participants to notify
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

    // Get active devices for each participant (last seen < 1 hour)
    const { data: devices, error: deviceError } = await supabase
      .from("profile_devices")
      .select("user_id, fcm_token, platform")
      .in("user_id", recipientUserIds)
      .gt("last_seen", new Date(Date.now() - 1000 * 60 * 60).toISOString()); // Last hour

    if (deviceError) {
      console.error("Error fetching devices:", deviceError);
      // Continue without devices - not critical
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

    // Check if Firebase is configured
    if (!firebaseProjectId || !firebasePrivateKey || !firebaseClientEmail) {
      console.warn("Firebase not configured - skipping notifications");
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
    let totalNotificationsSent = 0;
    const recipientsSummary: Array<{ user_id: string; device_count: number }> = [];

    for (const [userId, userDevices] of devicesByUser.entries()) {
      for (const device of userDevices) {
        try {
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

          // Call Firebase Cloud Messaging API
          // Note: This would require proper Firebase authentication
          // For now, we log the attempt
          console.log(
            `Sending FCM notification to ${device.fcm_token} on ${device.platform}`
          );

          // In production, call Firebase API:
          // const response = await fetch(
          //   `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
          //   {
          //     method: 'POST',
          //     headers: {
          //       'Authorization': `Bearer ${accessToken}`,
          //       'Content-Type': 'application/json',
          //     },
          //     body: JSON.stringify(fcmMessage),
          //   }
          // );

          totalNotificationsSent++;
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

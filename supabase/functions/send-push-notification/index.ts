import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { JWT } from 'npm:google-auth-library';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Get Webhook Payload
    const payload = await req.json();
    const record = payload.record; // The newly inserted row

    if (!record || !record.user_id) {
      return new Response(JSON.stringify({ error: 'Invalid payload record.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 2. Initialize Supabase Service Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 3. Fetch device tokens for the recipient user
    const { data: tokenRows, error: tokenError } = await supabase
      .from('user_fcm_tokens')
      .select('token')
      .eq('user_id', record.user_id);

    if (tokenError) {
      throw tokenError;
    }

    if (!tokenRows || tokenRows.length === 0) {
      return new Response(JSON.stringify({ message: 'No registered tokens found for user.' }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 4. Authenticate with Google / Firebase
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!serviceAccountJson) {
      throw new Error('Missing FIREBASE_SERVICE_ACCOUNT env variable.');
    }
    const serviceAccount = JSON.parse(serviceAccountJson);

    let jwtClient;
    try {
      jwtClient = new JWT({
        email: serviceAccount.client_email,
        key: serviceAccount.private_key,
        scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
      });
    } catch (jwtErr) {
      throw new Error(`JWT construction failed: ${jwtErr.message}. keys in serviceAccount: ${Object.keys(serviceAccount).join(', ')}`);
    }

    const credentials = await jwtClient.authorize();
    const accessToken = credentials.access_token;
    if (!accessToken) {
      throw new Error('Failed to retrieve Firebase access token.');
    }

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

    // 5. Send FCM pushes
    // We use a DATA-ONLY message (no top-level "notification" block).
    //
    // Why: when a "notification" block is present and the app is in the
    // background or killed, the Android FCM SDK shows the notification
    // automatically in the system tray but does NOT call the Dart
    // onBackgroundMessage handler — so our data (post_id, type) is lost.
    //
    // With a data-only message, onBackgroundMessage is always called and we
    // display the notification ourselves via flutter_local_notifications,
    // giving us full control in all app states (foreground / background /
    // terminated).
    const results: any[] = [];
    const sendPromises = tokenRows.map(async (row: { token: string }) => {
      const token = row.token;

      try {
        const response = await fetch(fcmUrl, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token: token,
              // Data-only — all fields must be strings.
              data: {
                title: 'Focus Fox',
                body: String(record.message ?? ''),
                post_id: String(record.post_id ?? ''),
                type: String(record.type ?? ''),
                answer_id: String(record.answer_id ?? ''),
              },
              android: {
                // HIGH priority wakes the device even in Doze mode.
                priority: 'high',
              },
              apns: {
                headers: {
                  // Required for iOS data-only messages to be delivered in
                  // background (content-available = 1).
                  'apns-priority': '5',
                },
                payload: {
                  aps: {
                    'content-available': 1,
                  },
                },
              },
            },
          }),
        });

        const respText = await response.text();
        results.push({
          token: token.substring(0, 15) + '...',
          status: response.status,
          response: respText
        });

        if (!response.ok) {
          console.error(`FCM error for token ${token}:`, respText);

          // If token is invalid or unregistered, delete it from the table.
          if (
            response.status === 404 ||
            respText.includes('UNREGISTERED') ||
            respText.includes('INVALID_ARGUMENT')
          ) {
            console.log(`Deleting invalid token: ${token}`);
            await supabase
              .from('user_fcm_tokens')
              .delete()
              .eq('token', token);
          }
        }
      } catch (err) {
        results.push({
          token: token.substring(0, 15) + '...',
          error: err.message
        });
      }
    });

    await Promise.all(sendPromises);

    return new Response(JSON.stringify({ success: true, count: tokenRows.length, results }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('Push notification execution error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

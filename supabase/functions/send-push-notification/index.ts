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

    const jwtClient = new JWT(
      serviceAccount.client_email,
      null,
      serviceAccount.private_key,
      ['https://www.googleapis.com/auth/firebase.messaging']
    );

    const credentials = await jwtClient.authorize();
    const accessToken = credentials.access_token;
    if (!accessToken) {
      throw new Error('Failed to retrieve Firebase access token.');
    }

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

    // 5. Send FCM pushes
    const sendPromises = tokenRows.map(async (row) => {
      const token = row.token;
      
      const response = await fetch(fcmUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: token,
            notification: {
              title: 'Focus Fox',
              body: record.message,
            },
            data: {
              post_id: record.post_id || '',
              type: record.type || '',
              answer_id: record.answer_id || '',
            },
            android: {
              priority: 'high',
              notification: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                },
              },
            },
          },
        }),
      });

      if (!response.ok) {
        const errText = await response.text();
        console.error(`FCM error for token ${token}:`, errText);
        
        // If token is invalid or unregistered, delete it from the table
        if (response.status === 404 || errText.includes('UNREGISTERED') || errText.includes('INVALID_ARGUMENT')) {
          console.log(`Deleting invalid token: ${token}`);
          await supabase
            .from('user_fcm_tokens')
            .delete()
            .eq('token', token);
        }
      }
    });

    await Promise.all(sendPromises);

    return new Response(JSON.stringify({ success: true, count: tokenRows.length }), {
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

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { AccessToken } from 'npm:livekit-server-sdk';

declare const Deno: any;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Get Auth Header (must be authenticated Supabase user)
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const body = await req.json();
    const { room_id, identity } = body;

    if (!room_id || !identity) {
      return new Response(JSON.stringify({ error: 'Missing room_id or identity' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 2. Fetch LiveKit API Keys from Env
    const apiKey = Deno.env.get('LIVEKIT_API_KEY');
    const apiSecret = Deno.env.get('LIVEKIT_API_SECRET');
    const wsUrl = Deno.env.get('LIVEKIT_URL');

    if (!apiKey || !apiSecret || !wsUrl) {
      return new Response(
        JSON.stringify({ error: 'LiveKit configuration is missing on server.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 3. Create AccessToken
    const at = new AccessToken(apiKey, apiSecret, {
      identity: identity,
      ttl: 7200,
    });

    at.addGrant({
      roomJoin: true,
      room: room_id,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
    });

    const jwt = await at.toJwt();

    return new Response(
      JSON.stringify({ token: jwt, ws_url: wsUrl }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error: any) {
    console.error('Error generating token:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

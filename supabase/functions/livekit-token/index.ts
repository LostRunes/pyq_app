import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { AccessToken } from 'npm:livekit-server-sdk';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

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

    // Verify the caller's JWT. The anon key alone passes the gateway's
    // verify_jwt check, so we must resolve an actual user here.
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );
    const jwt = authHeader.replace(/^Bearer\s+/i, '');
    const { data: userData, error: userError } = await supabase.auth.getUser(jwt);
    const user = userData?.user;
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    let body: any;
    try {
      body = await req.json();
    } catch (_) {
      body = null;
    }
    const room_id = body?.room_id;
    const name = body?.name;

    if (!room_id || typeof room_id !== 'string') {
      return new Response(JSON.stringify({ error: 'Missing room_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Identity is always the authenticated user's id (never trust the body),
    // so a caller cannot impersonate another participant.
    const identity = user.id;

    // Only issue tokens for existing, active, voice-enabled study rooms.
    const { data: roomRow, error: roomError } = await supabase
      .from('study_rooms')
      .select('id, is_voice_enabled, is_active')
      .eq('id', room_id)
      .maybeSingle();
    // Mirrors the app: is_active null is treated as active.
    if (roomError || !roomRow || roomRow.is_voice_enabled !== true || roomRow.is_active === false) {
      return new Response(JSON.stringify({ error: 'Room not found or not a voice room' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const displayName =
      typeof name === 'string' && name.trim() ? name.trim().slice(0, 64) : identity;

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
      name: displayName,
      ttl: 7200,
    });

    at.addGrant({
      roomJoin: true,
      room: room_id,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
    });

    const livekitJwt = await at.toJwt();

    return new Response(
      JSON.stringify({ token: livekitJwt, ws_url: wsUrl }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error: any) {
    console.error('Error generating token:', error);
    return new Response(JSON.stringify({ error: 'Failed to generate token' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

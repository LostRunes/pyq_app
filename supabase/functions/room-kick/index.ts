import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { RoomServiceClient } from 'npm:livekit-server-sdk';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

declare const Deno: any;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// Host of a personal study room removes a member:
//   1. records the removal in room_bans (blocks messages + voice tokens),
//   2. drops the user from the live LiveKit call if they are in it.
// Body: { room_id: string, user_id: string, unban?: boolean }
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return json({ error: 'Missing Authorization header' }, 401);

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );
    const jwt = authHeader.replace(/^Bearer\s+/i, '');
    const { data: userData, error: userError } = await supabase.auth.getUser(jwt);
    const caller = userData?.user;
    if (userError || !caller) return json({ error: 'Unauthorized' }, 401);

    let body: any = null;
    try { body = await req.json(); } catch (_) { /* empty body */ }
    const roomId = body?.room_id;
    const userId = body?.user_id;
    const unban = body?.unban === true;
    if (typeof roomId !== 'string' || typeof userId !== 'string') {
      return json({ error: 'room_id and user_id are required' }, 400);
    }
    if (userId === caller.id) return json({ error: 'You cannot remove yourself' }, 400);

    // Only the creator of a personal room may remove people from it.
    const { data: room, error: roomError } = await supabase
      .from('study_rooms')
      .select('id, type, created_by')
      .eq('id', roomId)
      .maybeSingle();
    if (roomError || !room) return json({ error: 'Room not found' }, 404);
    if (room.type !== 'personal' || String(room.created_by) !== caller.id) {
      return json({ error: 'Only the room host can do this' }, 403);
    }

    if (unban) {
      const { error } = await supabase
        .from('room_bans')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', userId);
      if (error) throw error;
      return json({ ok: true });
    }

    const { error: banError } = await supabase
      .from('room_bans')
      .upsert({ room_id: roomId, user_id: userId, banned_by: caller.id }, {
        onConflict: 'room_id,user_id',
      });
    if (banError) throw banError;

    // Drop them from the voice call. Not being in the call is fine.
    const wsUrl = Deno.env.get('LIVEKIT_URL');
    const apiKey = Deno.env.get('LIVEKIT_API_KEY');
    const apiSecret = Deno.env.get('LIVEKIT_API_SECRET');
    if (wsUrl && apiKey && apiSecret) {
      const host = wsUrl.replace(/^ws(s?):\/\//i, 'http$1://');
      try {
        await new RoomServiceClient(host, apiKey, apiSecret).removeParticipant(roomId, userId);
      } catch (_) {
        // Participant not connected to voice.
      }
    }

    return json({ ok: true });
  } catch (error: any) {
    console.error('room-kick failed:', error);
    return json({ error: 'Failed to remove member' }, 500);
  }
});

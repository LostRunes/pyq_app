import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { RoomServiceClient } from 'npm:livekit-server-sdk';

declare const Deno: any;

// Rooms younger than this are skipped by the reconcile, so a room whose
// creator is still connecting isn't zeroed (and then closed) mid-join.
const RECONCILE_GRACE_MS = 2 * 60 * 1000;

async function reconcileParticipantCounts(supabase: any) {
  const apiKey = Deno.env.get('LIVEKIT_API_KEY');
  const apiSecret = Deno.env.get('LIVEKIT_API_SECRET');
  const wsUrl = Deno.env.get('LIVEKIT_URL');
  if (!apiKey || !apiSecret || !wsUrl) {
    console.warn('Reconcile skipped: LiveKit configuration is missing.');
    return { skipped: 'missing LiveKit config' };
  }

  try {
    const graceCutoff = new Date(Date.now() - RECONCILE_GRACE_MS).toISOString();
    const { data: rooms, error } = await supabase
      .from('study_rooms')
      .select('id, participant_count')
      .eq('is_voice_enabled', true)
      .eq('is_active', true)
      .lt('created_at', graceCutoff);
    if (error) throw error;
    if (!rooms || rooms.length === 0) return { updated: [] };

    // The LiveKit room name is the study_rooms id (see livekit-token).
    // listRooms only returns rooms that currently exist on LiveKit; a room
    // that isn't returned has nobody in it.
    const host = wsUrl.replace(/^wss:/, 'https:').replace(/^ws:/, 'http:');
    const roomService = new RoomServiceClient(host, apiKey, apiSecret);
    const liveRooms = await roomService.listRooms(rooms.map((r: any) => r.id));
    const liveCounts = new Map<string, number>(
      liveRooms.map((r: any) => [r.name, Number(r.numParticipants ?? 0)]),
    );

    const updated: { id: string; from: number; to: number }[] = [];
    for (const room of rooms) {
      const actual = liveCounts.get(room.id) ?? 0;
      if (room.participant_count === actual) continue;
      const { error: updateError } = await supabase
        .from('study_rooms')
        .update({ participant_count: actual })
        .eq('id', room.id);
      if (updateError) {
        console.error(`Reconcile failed for room ${room.id}:`, updateError);
        continue;
      }
      updated.push({ id: room.id, from: room.participant_count, to: actual });
    }
    return { updated };
  } catch (e: any) {
    console.error('Reconcile skipped: could not query LiveKit:', e);
    return { skipped: 'LiveKit query failed' };
  }
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 0. Reconcile participant_count with LiveKit's real occupancy. The app
    // only adjusts the count with +1/-1 on join/leave, so a crashed or killed
    // app leaves it too high forever (and the room never counts as empty).
    // Best effort: if LiveKit can't be reached, counts are left untouched.
    const reconciled = await reconcileParticipantCounts(supabase);

    // 1. Deactivate voice study rooms that have 0 active participants (excluding permanent rooms)
    const { data: deactivatedVoice, error: deactivateVoiceError } = await supabase
      .from('study_rooms')
      .update({ 
        is_active: false,
        ended_at: new Date().toISOString()
      })
      .eq('is_voice_enabled', true)
      .eq('is_active', true)
      // <= 0: a client's -1 landing right after a reconcile can dip below 0.
      .lte('participant_count', 0)
      .not('name', 'in', [
        'general voice lounge',
        'General Voice Lounge',
        'dsa griend',
        'dsa grind',
        'DSA Griend',
        'DSA Grind',
        'placement talkies',
        'Placement Talkies'
      ])
      .select('id, name');

    if (deactivateVoiceError) throw deactivateVoiceError;

    // 2. Deactivate personal text-only rooms (is_voice_enabled = false) with no activity for 15 minutes
    const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000).toISOString();
    const { data: deactivatedText, error: deactivateTextError } = await supabase
      .from('study_rooms')
      .update({
        is_active: false,
        ended_at: new Date().toISOString()
      })
      .eq('type', 'personal')
      .eq('is_voice_enabled', false)
      .eq('is_active', true)
      .lt('last_message_at', fifteenMinutesAgo)
      .select('id, name');

    if (deactivateTextError) throw deactivateTextError;

    // 3. Delete custom/personal rooms (and cascaded messages) that have ended > 15 minutes ago
    const { data: deleted, error: deleteError } = await supabase
      .from('study_rooms')
      .delete()
      .in('type', ['custom', 'personal'])
      .eq('is_active', false)
      .lt('ended_at', fifteenMinutesAgo)
      .select('id, name');

    if (deleteError) throw deleteError;

    return new Response(JSON.stringify({ 
      success: true,
      reconciled,
      deactivatedVoice,
      deactivatedText,
      deleted
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    console.error('Cleanup execution error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

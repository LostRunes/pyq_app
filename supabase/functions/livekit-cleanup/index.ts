import "jsr:@supabase/functions-js/edge-runtime.d.ts";
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
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Deactivate voice study rooms that have 0 active participants (excluding permanent rooms)
    const { data: deactivatedVoice, error: deactivateVoiceError } = await supabase
      .from('study_rooms')
      .update({ 
        is_active: false,
        ended_at: new Date().toISOString()
      })
      .eq('is_voice_enabled', true)
      .eq('is_active', true)
      .eq('participant_count', 0)
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

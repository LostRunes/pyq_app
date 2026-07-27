import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiSecret = Deno.env.get("CLOUDINARY_API_SECRET");
    const apiKey = Deno.env.get("CLOUDINARY_API_KEY");

    if (!apiSecret || !apiKey) {
      return new Response(
        JSON.stringify({ error: "Cloudinary credentials not configured on server." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const timestamp = Math.round(new Date().getTime() / 1000).toString();
    const uploadPreset = "student_doubts_upload";

    // Sort parameters alphabetically: timestamp then upload_preset
    const dataToSign = `timestamp=${timestamp}&upload_preset=${uploadPreset}${apiSecret}`;

    // SHA-1 hash using native Web Crypto API
    const messageBuffer = new TextEncoder().encode(dataToSign);
    const hashBuffer = await crypto.subtle.digest("SHA-1", messageBuffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const signature = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

    return new Response(
      JSON.stringify({
        signature,
        timestamp,
        apiKey,
        uploadPreset,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

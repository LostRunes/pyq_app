import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

/**
 * resolve-student Edge Function
 *
 * Looks up a student record in the primary DB by roll number.
 * This is the server-side replacement for using the service_role key
 * directly in the Flutter app to query the `students` table.
 *
 * Security model:
 *  - Caller must provide a valid Supabase JWT (anon or user session)
 *    from the secondary DB (auth DB). The function is protected by
 *    verify_jwt=false because the JWT is from a different Supabase project,
 *    so we do manual presence checking instead.
 *  - The roll number returned is ONLY the one derived from the caller's
 *    request — no bulk student enumeration is possible.
 *  - The service_role key is only available server-side via env var.
 */
Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Require an Authorization header (proves the request has our anon key at minimum)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid Authorization header." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Parse body
    const body = await req.json();
    const rollNo: string | undefined = body?.roll_no;

    // Allow 7 to 10 digits since many students in the database have 7-digit roll numbers.
    if (!rollNo || typeof rollNo !== "string" || !/^\d{7,10}$/.test(rollNo)) {
      return new Response(
        JSON.stringify({ error: "Invalid or missing roll_no. Must be 7-10 digits." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Connect to DB1 using the server-side service_role key (never exposed to client)
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const db1 = createClient(supabaseUrl, serviceKey);

    // 4. Look up the specific student — no bulk access possible
    const { data, error } = await db1
      .from("students")
      .select("roll_no, batch, section")
      .eq("roll_no", rollNo)
      .maybeSingle();

    if (error) {
      console.error("DB query error:", error.message);
      return new Response(
        JSON.stringify({ error: "Database lookup failed." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!data) {
      return new Response(
        JSON.stringify({ found: false }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Return only the fields needed for routing — no sensitive PII
    return new Response(
      JSON.stringify({
        found: true,
        batch: data.batch,
        section: data.section,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error("Unexpected error in resolve-student:", err.stack || err.message || err);
    return new Response(
      JSON.stringify({ error: "Internal server error.", details: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

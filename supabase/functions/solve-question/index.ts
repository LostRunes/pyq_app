import "jsr:@supabase/functions-js/edge-runtime.d.ts";

declare const Deno: any;

Deno.serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const apiKey = Deno.env.get("GEMINI_API_KEY");

    if (!apiKey) {
      throw new Error("GEMINI_API_KEY is not set");
    }

    const { question } = await req.json();

    const response = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-preview:generateContent?key=" + apiKey,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                {
                  text: `
          Solve this engineering exam question step-by-step.
          
          Structure your response clearly with these sections:
          🧠 UNDERSTANDING: Briefly explain the core concept.
          📐 FORMULAS & STEPS: Detail the calculation process and formulas used.
          ✅ FINAL ANSWER: State the final result clearly.

          Make it exam-ready and professional.

          Question:
          ${question}
                  `,
                },
              ],
            },
          ],
        }),
      }
    );

    const data = await response.json();
    const answer = data.candidates?.[0]?.content?.parts?.[0]?.text || "I couldn't generate a solution at this moment. Please try again.";

    return new Response(
      JSON.stringify({ answer }),
      {
        headers: {
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message || 'Unknown error occurred' }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      }
    );
  }
});

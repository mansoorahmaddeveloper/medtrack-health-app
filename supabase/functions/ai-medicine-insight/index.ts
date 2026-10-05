import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const DISCLAIMER =
  "Informational only — not medical advice. Consult a licensed professional.";

Deno.serve(async (req) => {
  const { medicine, condition } = await req.json();
  return new Response(
    JSON.stringify({
      summary: `${DISCLAIMER} General use of ${medicine} for ${condition}: follow prescriber guidance and monitor for side effects.`,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});

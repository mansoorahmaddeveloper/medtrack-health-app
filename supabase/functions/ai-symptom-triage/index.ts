import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  const { symptoms } = await req.json();
  const urgent =
    typeof symptoms === "string" &&
    /chest pain|cannot breathe|unconscious|severe bleeding/i.test(symptoms);
  return new Response(
    JSON.stringify({
      specialist: urgent ? "Emergency medicine" : "General physician",
      urgency: urgent ? "emergency" : "soon",
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});

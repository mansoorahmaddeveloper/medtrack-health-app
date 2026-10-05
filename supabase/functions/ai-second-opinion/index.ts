import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  const body = await req.json();
  const requestId = crypto.randomUUID();
  console.log("Second opinion request", requestId, body.patient_id);
  return new Response(JSON.stringify({ request_id: requestId }), {
    headers: { "Content-Type": "application/json" },
  });
});

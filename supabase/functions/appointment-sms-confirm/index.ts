import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  const { appointment_id, phone } = await req.json();
  console.log("SMS confirmation for appointment", appointment_id, phone);
  return new Response(JSON.stringify({ sent: true }), {
    headers: { "Content-Type": "application/json" },
  });
});

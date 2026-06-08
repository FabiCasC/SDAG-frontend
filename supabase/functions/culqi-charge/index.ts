import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405, headers: corsHeaders });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const culqiSecretKey = Deno.env.get("CULQI_SECRET_KEY");
    if (!supabaseUrl || !serviceRoleKey || !culqiSecretKey) {
      return new Response("Missing server configuration", { status: 500, headers: corsHeaders });
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice("Bearer ".length) : null;
    if (!token) return new Response("Unauthorized", { status: 401, headers: corsHeaders });

    const admin = createClient(supabaseUrl, serviceRoleKey);
    const { data: authData, error: authErr } = await admin.auth.getUser(token);
    if (authErr || !authData.user) return new Response("Unauthorized", { status: 401, headers: corsHeaders });

    const body = await req.json();
    const sourceId = String(body.source_id ?? "").trim();
    const email = String(body.email ?? "").trim().toLowerCase();
    const amount = Number(body.amount ?? 0);
    const description = String(body.description ?? "").trim();

    if (!sourceId) return Response.json({ error: "source_id requerido" }, { status: 400, headers: corsHeaders });
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      return Response.json({ error: "email inválido" }, { status: 400, headers: corsHeaders });
    }
    if (!Number.isFinite(amount) || amount <= 0) {
      return Response.json({ error: "amount inválido" }, { status: 400, headers: corsHeaders });
    }

    const response = await fetch("https://api.culqi.com/v2/charges", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${culqiSecretKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount,
        currency_code: "PEN",
        email,
        source_id: sourceId,
        description: description.length > 0 ? description : "Reserva SDAG",
      }),
    });

    const json = await response.json().catch(() => ({}));
    if (response.status !== 201) {
      return Response.json(
        { error: "charge_failed", details: json },
        { status: 400, headers: corsHeaders },
      );
    }

    return Response.json(
      { charge_id: json?.id ?? null, charge: json },
      { status: 200, headers: corsHeaders },
    );
  } catch (e) {
    return Response.json({ error: String(e?.message ?? e) }, { status: 500, headers: corsHeaders });
  }
});

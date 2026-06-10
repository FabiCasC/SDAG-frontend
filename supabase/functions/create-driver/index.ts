import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405, headers: corsHeaders });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return new Response("Missing server configuration", { status: 500, headers: corsHeaders });
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice("Bearer ".length) : null;
    if (!token) return new Response("Unauthorized", { status: 401, headers: corsHeaders });

    const admin = createClient(supabaseUrl, serviceRoleKey);

    const { data: authData, error: authErr } = await admin.auth.getUser(token);
    if (authErr || !authData.user) return new Response("Unauthorized", { status: 401, headers: corsHeaders });

    const { data: callerProfile } = await admin
      .from("profiles")
      .select("role")
      .eq("id", authData.user.id)
      .maybeSingle();
    if (callerProfile?.role !== "admin") return new Response("Forbidden", { status: 403, headers: corsHeaders });

    const body = await req.json();
    const firstName = String(body.first_name ?? "").trim();
    const lastName = String(body.last_name ?? "").trim();
    const dni = String(body.dni ?? "").trim();
    const phone = body.phone == null ? null : String(body.phone).trim();
    const email = String(body.email ?? "").trim().toLowerCase();
    const password = String(body.password ?? "");
    const vehicleId = body.vehicle_id ? String(body.vehicle_id) : null;
    const commissionPct = Number(body.commission_pct ?? 15);

    if (!firstName || !lastName) return Response.json({ error: "Nombre y apellido requeridos" }, { status: 400, headers: corsHeaders });
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return Response.json({ error: "Correo inválido" }, { status: 400, headers: corsHeaders });
    if (password.trim().length < 8) return Response.json({ error: "Contraseña mínimo 8 caracteres" }, { status: 400, headers: corsHeaders });

    // Crea usuario en Auth
    const { data: createdAuth, error: createAuthErr } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });
    if (createAuthErr || !createdAuth.user) {
      return Response.json({ error: createAuthErr?.message ?? "No se pudo crear el usuario" }, { status: 400, headers: corsHeaders });
    }

    const userId = createdAuth.user.id;

    try {
      // Crea profile
      const { error: profileErr } = await admin.from("profiles").upsert({
        id: userId,
        role: "driver",
        first_name: firstName,
        last_name: lastName,
        dni: dni || null,
        phone: phone && phone.length > 0 ? phone : null,
        email,
        name: `${firstName} ${lastName}`.trim(),
      });
      if (profileErr) throw profileErr;

      // Obtiene datos del vehículo seleccionado
      let plate = body.plate ? String(body.plate).trim().toUpperCase() : "SIN-PLACA";
      let vehicleType = body.vehicle_type ? String(body.vehicle_type) : "Combi";
      let capacity = Number(body.capacity ?? 14);

      if (vehicleId) {
        const { data: vehicle } = await admin
          .from("vehicles")
          .select("plate, vehicle_type, total_seats")
          .eq("id", vehicleId)
          .single();
        if (vehicle) {
          plate = vehicle.plate;
          vehicleType = vehicle.vehicle_type;
          capacity = vehicle.total_seats;
        }
      }

      // Crea driver
      const { data: driverData, error: driverErr } = await admin.from("drivers").insert({
        profile_id: userId,
        plate,
        vehicle_type: vehicleType,
        capacity,
        commission_pct: commissionPct,
        cuenta_activa: true,
        pago_confirmado: true,
        estado: "disponible",
      }).select("id").single();
      if (driverErr) throw driverErr;

      // Enlaza vehículo al driver si se seleccionó uno
      if (vehicleId && driverData) {
        await admin.from("vehicles")
          .update({ driver_id: driverData.id })
          .eq("id", vehicleId);
      }

      return Response.json({ user_id: userId, driver_id: driverData.id }, { status: 200, headers: corsHeaders });

    } catch (e) {
      await admin.auth.admin.deleteUser(userId);
      return Response.json({ error: String(e?.message ?? e) }, { status: 400, headers: corsHeaders });
    }
  } catch (e) {
    return Response.json({ error: String(e?.message ?? e) }, { status: 500, headers: corsHeaders });
  }
});

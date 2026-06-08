import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return new Response("Missing server configuration", { status: 500 });
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice("Bearer ".length) : null;
    if (!token) return new Response("Unauthorized", { status: 401 });

    const admin = createClient(supabaseUrl, serviceRoleKey);

    const { data: authData, error: authErr } = await admin.auth.getUser(token);
    if (authErr || !authData.user) return new Response("Unauthorized", { status: 401 });

    const callerId = authData.user.id;
    const { data: callerProfile, error: callerProfileErr } = await admin
      .from("profiles")
      .select("role")
      .eq("id", callerId)
      .maybeSingle();
    if (callerProfileErr) return new Response("Unauthorized", { status: 401 });
    if (callerProfile?.role !== "admin") return new Response("Forbidden", { status: 403 });

    const body = await req.json();
    const firstName = String(body.first_name ?? "").trim();
    const lastName = String(body.last_name ?? "").trim();
    const dni = String(body.dni ?? "").trim();
    const phone = body.phone == null ? null : String(body.phone).trim();
    const email = String(body.email ?? "").trim().toLowerCase();
    const password = String(body.password ?? "");
    const plate = String(body.plate ?? "").trim().toUpperCase();
    const vehicleType = String(body.vehicle_type ?? "").trim();
    const capacity = Number(body.capacity ?? 0);
    const commissionPct = Number(body.commission_pct ?? 0);

    if (!firstName || !lastName) return Response.json({ error: "Nombre y apellido requeridos" }, { status: 400 });
    if (!/^\d{8}$/.test(dni)) return Response.json({ error: "DNI inválido" }, { status: 400 });
    if (phone && !/^\d{9}$/.test(phone)) return Response.json({ error: "Teléfono inválido" }, { status: 400 });
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return Response.json({ error: "Correo inválido" }, { status: 400 });
    if (password.trim().length < 8) return Response.json({ error: "Contraseña inválida" }, { status: 400 });
    if (!/^[A-Z]{3}-\d{3}$/.test(plate)) return Response.json({ error: "Placa inválida" }, { status: 400 });
    if (!Number.isFinite(capacity) || capacity <= 0) return Response.json({ error: "Capacidad inválida" }, { status: 400 });
    if (!Number.isFinite(commissionPct) || commissionPct < 0 || commissionPct > 100) {
      return Response.json({ error: "Comisión inválida" }, { status: 400 });
    }

    const { data: createdAuth, error: createAuthErr } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });
    if (createAuthErr || !createdAuth.user) {
      return Response.json({ error: createAuthErr?.message ?? "No se pudo crear el usuario" }, { status: 400 });
    }

    const userId = createdAuth.user.id;
    try {
      const profileInsert = await admin.from("profiles").insert({
        id: userId,
        role: "driver",
        first_name: firstName,
        last_name: lastName,
        dni,
        phone: phone && phone.length > 0 ? phone : null,
        email,
        name: `${firstName} ${lastName}`.trim(),
      });
      if (profileInsert.error) throw profileInsert.error;

      const driverInsert = await admin.from("drivers").insert({
        profile_id: userId,
        plate,
        vehicle_type: vehicleType,
        capacity,
        commission_pct: commissionPct,
      }).select("id").single();
      if (driverInsert.error) throw driverInsert.error;

      return Response.json({ user_id: userId, driver_id: driverInsert.data.id }, { status: 200 });
    } catch (e) {
      await admin.auth.admin.deleteUser(userId);
      return Response.json({ error: String(e?.message ?? e) }, { status: 400 });
    }
  } catch (e) {
    return Response.json({ error: String(e?.message ?? e) }, { status: 500 });
  }
});

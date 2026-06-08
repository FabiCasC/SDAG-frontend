declare const Deno: {
  env: { get: (key: string) => string | undefined };
  serve: (handler: (req: Request) => Response | Promise<Response>) => void;
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function textResponse(text: string, status: number): Response {
  return new Response(text, { status, headers: corsHeaders });
}

function getBearerToken(req: Request): string | null {
  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.slice('Bearer '.length).trim();
  return token.length > 0 ? token : null;
}

async function fetchJson(url: string, init: RequestInit): Promise<{ status: number; json: any; raw: string }> {
  const res = await fetch(url, init);
  const raw = await res.text();
  const json = (() => {
    try {
      return JSON.parse(raw);
    } catch (_) {
      return null;
    }
  })();
  return { status: res.status, json, raw };
}

Deno.serve(async (req: Request) => {
  try {
    if (req.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }
    if (req.method !== 'POST') {
      return textResponse('Method not allowed', 405);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!supabaseUrl || !serviceRoleKey) {
      return textResponse('Missing server configuration', 500);
    }

    const jwt = getBearerToken(req);
    if (!jwt) return textResponse('Unauthorized', 401);

    const callerAuth = await fetchJson(`${supabaseUrl}/auth/v1/user`, {
      method: 'GET',
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${jwt}`,
      },
    });
    const callerId = callerAuth.json?.id?.toString();
    if (callerAuth.status !== 200 || !callerId) return textResponse('Unauthorized', 401);

    const roleResp = await fetchJson(
      `${supabaseUrl}/rest/v1/profiles?select=role&id=eq.${encodeURIComponent(callerId)}`,
      {
        method: 'GET',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
        },
      },
    );
    const callerRole = Array.isArray(roleResp.json) ? roleResp.json[0]?.role?.toString() : null;
    if (roleResp.status !== 200 || callerRole !== 'admin') return textResponse('Forbidden', 403);

    const body = (await req.json().catch(() => null)) as Record<string, unknown> | null;
    if (!body) return jsonResponse({ error: 'invalid_body' }, 400);

    const firstName = String(body.first_name ?? '').trim();
    const lastName = String(body.last_name ?? '').trim();
    const dni = String(body.dni ?? '').trim();
    const phone = String(body.phone ?? '').trim();
    const email = String(body.email ?? '').trim().toLowerCase();
    const password = String(body.password ?? '').trim();
    const plate = String(body.plate ?? '').trim().toUpperCase();
    const vehicleType = String(body.vehicle_type ?? '').trim();
    const capacity = Number(body.capacity ?? 0);
    const commissionPct = Number(body.commission_pct ?? 0);

    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return jsonResponse({ error: 'invalid_email' }, 400);
    if (password.length < 8) return jsonResponse({ error: 'invalid_password' }, 400);
    if (!firstName || !lastName) return jsonResponse({ error: 'invalid_name' }, 400);
    if (!dni) return jsonResponse({ error: 'invalid_dni' }, 400);
    if (!plate) return jsonResponse({ error: 'invalid_plate' }, 400);
    if (!Number.isFinite(capacity) || capacity <= 0) return jsonResponse({ error: 'invalid_capacity' }, 400);
    if (!Number.isFinite(commissionPct) || commissionPct < 0 || commissionPct > 100) {
      return jsonResponse({ error: 'invalid_commission_pct' }, 400);
    }

    const createUser = await fetchJson(`${supabaseUrl}/auth/v1/admin/users`, {
      method: 'POST',
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          role: 'driver',
          first_name: firstName,
          last_name: lastName,
        },
      }),
    });
    const newUserId = createUser.json?.id?.toString();
    if ((createUser.status !== 200 && createUser.status !== 201) || !newUserId) {
      return jsonResponse({ error: 'create_user_failed', details: createUser.json ?? createUser.raw }, 400);
    }

    const profileInsert = await fetchJson(`${supabaseUrl}/rest/v1/profiles`, {
      method: 'POST',
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        'Content-Type': 'application/json',
        Prefer: 'return=representation',
      },
      body: JSON.stringify({
        id: newUserId,
        role: 'driver',
        first_name: firstName,
        last_name: lastName,
        dni,
        phone,
        email,
      }),
    });
    if (profileInsert.status !== 201 && profileInsert.status !== 200) {
      return jsonResponse({ error: 'profile_insert_failed', details: profileInsert.json ?? profileInsert.raw }, 400);
    }

    const driverInsert = await fetchJson(`${supabaseUrl}/rest/v1/drivers`, {
      method: 'POST',
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        'Content-Type': 'application/json',
        Prefer: 'return=representation',
      },
      body: JSON.stringify({
        profile_id: newUserId,
        plate,
        vehicle_type: vehicleType,
        capacity,
        commission_pct: commissionPct,
        cuenta_activa: true,
      }),
    });
    if (driverInsert.status !== 201 && driverInsert.status !== 200) {
      return jsonResponse({ error: 'driver_insert_failed', details: driverInsert.json ?? driverInsert.raw }, 400);
    }

    return jsonResponse({ user_id: newUserId }, 200);
  } catch (e: unknown) {
    const message = e instanceof Error ? e.message : String(e);
    return jsonResponse({ error: message }, 500);
  }
});

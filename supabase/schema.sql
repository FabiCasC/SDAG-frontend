-- =========================================================
-- SDAG / Supabase Schema COMBINADO
-- Fusión del schema de Trae + schema completo
-- =========================================================

-- 0) EXTENSIONES
create extension if not exists pgcrypto;
create extension if not exists citext;

-- 1) TIPOS (ENUMS)
do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type public.app_role as enum ('passenger', 'driver', 'admin');
  end if;
  if not exists (select 1 from pg_type where typname = 'driver_state') then
    create type public.driver_state as enum ('disponible','activo','en_ruta','finalizado','inactivo','bloqueado');
  end if;
  if not exists (select 1 from pg_type where typname = 'trip_status') then
    create type public.trip_status as enum ('esperando','lleno','en_ruta','completado','cancelado');
  end if;
  if not exists (select 1 from pg_type where typname = 'reservation_status') then
    create type public.reservation_status as enum ('activa','cancelada','completada','reembolsada');
  end if;
  if not exists (select 1 from pg_type where typname = 'payment_status') then
    create type public.payment_status as enum ('pendiente','confirmado','fallido','reembolsado','cancelado');
  end if;
  if not exists (select 1 from pg_type where typname = 'payment_brand') then
    create type public.payment_brand as enum ('visa','mastercard','yape','tarjeta','otro');
  end if;
  if not exists (select 1 from pg_type where typname = 'news_type') then
    create type public.news_type as enum ('incidencia','novedad');
  end if;
  if not exists (select 1 from pg_type where typname = 'boarding_status') then
    create type public.boarding_status as enum ('pendiente','abordo','no_abordo','cancelado');
  end if;
  if not exists (select 1 from pg_type where typname = 'commission_request_status') then
    create type public.commission_request_status as enum ('sin_solicitud','pendiente','confirmado_admin','recibido_conductor');
  end if;
  if not exists (select 1 from pg_type where typname = 'chat_message_type') then
    create type public.chat_message_type as enum ('normal','alternative_pickup','esperame');
  end if;
end $$;

-- 2) FUNCIONES UTILITARIAS
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- 3) TABLAS BASE

-- PROFILES
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.app_role not null default 'passenger',
  name text,
  email citext unique,
  phone text unique,
  dni text unique,
  first_name text,
  last_name text,
  birth_date date,
  preferred_pickup text,
  is_blocked boolean not null default false,
  has_active_reservation boolean not null default false,
  fcm_token text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_phone_chk check (phone is null or length(phone) between 6 and 20),
  constraint profiles_dni_chk check (dni is null or length(dni) between 6 and 20)
);

create or replace trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- FUNCIONES DE ROL (después de profiles)
create or replace function public.current_app_role()
returns public.app_role language sql stable security definer set search_path = public as $$
  select coalesce(
    (select role from public.profiles where id = auth.uid()),
    'passenger'::public.app_role
  );
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select public.current_app_role() = 'admin'::public.app_role;
$$;

create or replace function public.is_driver()
returns boolean language sql stable security definer set search_path = public as $$
  select public.current_app_role() = 'driver'::public.app_role;
$$;

-- ROUTES
create table if not exists public.routes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  from_label text not null,
  to_label text not null,
  polyline jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint routes_name_chk check (length(trim(name)) > 0)
);

create index if not exists idx_routes_active on public.routes(active);

create or replace trigger trg_routes_updated_at
before update on public.routes
for each row execute function public.set_updated_at();

-- PICKUP POINTS
create table if not exists public.pickup_points (
  id uuid primary key default gen_random_uuid(),
  route_id uuid references public.routes(id) on delete set null,
  address text not null,
  lat numeric(10,7),
  lng numeric(10,7),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint pickup_points_address_chk check (length(trim(address)) > 0)
);

create index if not exists idx_pickup_points_route_id on public.pickup_points(route_id);

-- 4) TABLAS CON RELACIONES

-- DRIVERS (combina campos de Trae + campos completos)
create table if not exists public.drivers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique not null references public.profiles(id) on delete cascade,
  plate text unique,
  vehicle_type text,
  capacity integer not null default 0,
  commission_pct numeric(5,2) not null default 15.00,
  pago_confirmado boolean not null default false,
  last_pago_confirmado_at timestamptz,          -- de Trae
  cuenta_activa boolean not null default true,
  estado public.driver_state not null default 'disponible',
  rating_avg numeric(3,2) not null default 0,
  rating_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint drivers_capacity_chk check (capacity >= 0 and capacity <= 99),
  constraint drivers_commission_chk check (commission_pct >= 0 and commission_pct <= 100)
);

create index if not exists idx_drivers_profile_id on public.drivers(profile_id);
create index if not exists idx_drivers_estado on public.drivers(estado);

create or replace trigger trg_drivers_updated_at
before update on public.drivers
for each row execute function public.set_updated_at();

-- VEHICLES
create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  plate text unique not null,
  label text,
  vehicle_type text,
  total_seats integer not null default 0,
  driver_id uuid references public.drivers(id) on delete set null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint vehicles_seats_chk check (total_seats >= 0 and total_seats <= 99),
  constraint vehicles_plate_chk check (length(trim(plate)) > 0)
);

create index if not exists idx_vehicles_driver_id on public.vehicles(driver_id);

create or replace trigger trg_vehicles_updated_at
before update on public.vehicles
for each row execute function public.set_updated_at();

-- TRIPS
create table if not exists public.trips (
  id uuid primary key default gen_random_uuid(),
  route_id uuid references public.routes(id) on delete set null,
  driver_id uuid references public.drivers(id) on delete set null,
  vehicle_id uuid references public.vehicles(id) on delete set null,
  status public.trip_status not null default 'esperando',
  scheduled_departure_at timestamptz,
  started_at timestamptz,
  finished_at timestamptz,
  eta_minutes integer,
  base_fare numeric(10,2) not null default 15.00,
  amount_total numeric(10,2) not null default 0,
  -- alias para compatibilidad con código de Trae
  amount numeric(10,2) generated always as (amount_total) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trips_eta_chk check (eta_minutes is null or eta_minutes between 0 and 999),
  constraint trips_amount_chk check (amount_total >= 0),
  constraint trips_fare_chk check (base_fare >= 0)
);

create index if not exists idx_trips_driver_id on public.trips(driver_id);
create index if not exists idx_trips_route_id on public.trips(route_id);
create index if not exists idx_trips_status on public.trips(status);
create index if not exists idx_trips_created_at on public.trips(created_at);

create or replace trigger trg_trips_updated_at
before update on public.trips
for each row execute function public.set_updated_at();

-- RESERVATIONS
create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete set null,
  passenger_profile_id uuid references public.profiles(id) on delete set null,
  pickup_point text,
  pickup_point_id uuid references public.pickup_points(id) on delete set null,
  seats integer[] not null default '{}'::integer[],
  status public.reservation_status not null default 'activa',
  vehiculo_partio boolean not null default false,
  additional_charge_pending boolean not null default false,
  additional_charge_amount numeric(10,2) not null default 0,
  amount numeric(10,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reservations_charge_chk check (additional_charge_amount >= 0),
  constraint reservations_amount_chk check (amount >= 0)
);

create index if not exists idx_reservations_trip_id on public.reservations(trip_id);
create index if not exists idx_reservations_passenger_profile_id on public.reservations(passenger_profile_id);
create index if not exists idx_reservations_status on public.reservations(status);
create unique index if not exists reservations_unique_active_passenger_trip
on public.reservations (trip_id, passenger_profile_id)
where status = 'activa';

create or replace trigger trg_reservations_updated_at
before update on public.reservations
for each row execute function public.set_updated_at();

-- RESERVATION COMPANIONS
create table if not exists public.reservation_companions (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid not null references public.reservations(id) on delete cascade,
  seat_number integer not null,
  full_name text not null,
  dni text not null,
  phone text not null,
  created_at timestamptz not null default now(),
  constraint companions_seat_chk check (seat_number between 1 and 99),
  constraint companions_name_chk check (length(trim(full_name)) > 0)
);

create unique index if not exists uidx_companions_reservation_seat
on public.reservation_companions(reservation_id, seat_number);

-- MANIFESTS
create table if not exists public.manifests (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid unique references public.trips(id) on delete cascade,
  estado text not null default 'en_curso',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint manifests_estado_chk check (estado in ('en_curso','completado','cancelado'))
);

create or replace trigger trg_manifests_updated_at
before update on public.manifests
for each row execute function public.set_updated_at();

-- MANIFEST ENTRIES
create table if not exists public.manifest_entries (
  id uuid primary key default gen_random_uuid(),
  manifest_id uuid not null references public.manifests(id) on delete cascade,
  passenger_profile_id uuid references public.profiles(id) on delete set null,
  reservation_id uuid references public.reservations(id) on delete set null,
  first_name text,
  last_name text,
  dni text,
  phone text,
  seat_number integer not null,
  pickup_text text not null,
  boarding_status public.boarding_status not null default 'pendiente',
  fuera_de_ruta boolean not null default false,
  created_at timestamptz not null default now(),
  constraint entries_seat_chk check (seat_number between 1 and 99),
  constraint entries_pickup_chk check (length(trim(pickup_text)) > 0)
);

create unique index if not exists uidx_entries_manifest_seat
on public.manifest_entries(manifest_id, seat_number);
create index if not exists idx_entries_passenger on public.manifest_entries(passenger_profile_id);

-- PAYMENTS
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid not null references public.reservations(id) on delete cascade,
  amount numeric(10,2) not null,
  status public.payment_status not null default 'pendiente',
  receipt_number text,
  provider text,
  created_at timestamptz not null default now(),
  constraint payments_amount_chk check (amount >= 0)
);

create index if not exists idx_payments_reservation_id on public.payments(reservation_id);
create index if not exists idx_payments_status on public.payments(status);
create unique index if not exists uidx_payments_receipt
on public.payments(receipt_number) where receipt_number is not null;

-- PAYMENT METHODS
create table if not exists public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique not null references public.profiles(id) on delete cascade,
  brand public.payment_brand not null default 'otro',
  last4 text not null,
  token text not null,
  save_for_future boolean not null default true,
  created_at timestamptz not null default now(),
  constraint payment_methods_last4_chk check (length(last4) between 2 and 8)
);

-- DRIVER PAYOUT REQUESTS (de Trae — usado por el código de pagos admin)
create table if not exists public.driver_payout_requests (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pendiente',
  gross_amount numeric(10,2) not null default 0,
  commission_amount numeric(10,2) not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists idx_payout_requests_profile_id on public.driver_payout_requests(profile_id);

-- DRIVER PAYOUTS (de Trae — historial de pagos confirmados)
create table if not exists public.driver_payouts (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  gross_amount numeric(10,2) not null default 0,
  commission_amount numeric(10,2) not null default 0,
  status text not null default 'Confirmado',
  created_at timestamptz not null default now()
);

create index if not exists idx_payouts_profile_id on public.driver_payouts(profile_id);

-- TRIP MESSAGES
create table if not exists public.trip_messages (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  sender_profile_id uuid references public.profiles(id) on delete set null,
  sender_role public.app_role not null,
  message_type public.chat_message_type not null default 'normal',
  body text not null,
  created_at timestamptz not null default now(),
  constraint trip_messages_body_chk check (length(trim(body)) > 0)
);

create index if not exists idx_trip_messages_trip_id on public.trip_messages(trip_id, created_at);

-- DRIVER GROUP MESSAGES
create table if not exists public.driver_group_messages (
  id uuid primary key default gen_random_uuid(),
  sender_driver_id uuid references public.drivers(id) on delete set null,
  sender_name text not null,
  sender_plate text not null,
  body text not null,
  created_at timestamptz not null default now(),
  constraint group_messages_body_chk check (length(trim(body)) > 0)
);

create index if not exists idx_group_messages_created on public.driver_group_messages(created_at);

-- NEWS POSTS (combina campos de ambos: type enum + driver_profile_id + driver_name de Trae)
create table if not exists public.news_posts (
  id uuid primary key default gen_random_uuid(),
  type public.news_type not null,
  title text not null,
  body text not null,
  -- campos de Trae para compatibilidad con el código
  text text generated always as (body) stored,
  author_driver_id uuid references public.drivers(id) on delete set null,
  driver_profile_id uuid references public.profiles(id) on delete set null,
  driver_name text,
  created_at timestamptz not null default now(),
  constraint news_title_chk check (length(trim(title)) > 0),
  constraint news_body_chk check (length(trim(body)) > 0)
);

create index if not exists idx_news_posts_created_at on public.news_posts(created_at);
create index if not exists idx_news_type_created on public.news_posts(type, created_at);

-- RATINGS
create table if not exists public.ratings (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade,
  rater_profile_id uuid references public.profiles(id) on delete set null,
  driver_id uuid references public.drivers(id) on delete set null,
  stars integer not null,
  comment text,
  created_at timestamptz not null default now(),
  constraint ratings_stars_chk check (stars between 1 and 5)
);

create index if not exists idx_ratings_driver on public.ratings(driver_id, created_at);
create unique index if not exists uidx_ratings_trip_rater
on public.ratings(trip_id, rater_profile_id);

-- DRIVER LOCATIONS
create table if not exists public.driver_locations (
  driver_id uuid primary key references public.drivers(id) on delete cascade,
  vehicle_id uuid references public.vehicles(id) on delete set null,
  trip_id uuid references public.trips(id) on delete set null,
  estado public.driver_state not null default 'disponible',
  lat numeric(10,7),
  lng numeric(10,7),
  eta_minutes integer,
  occupied_seats integer not null default 0,
  capacity integer not null default 0,
  updated_at timestamptz not null default now(),
  constraint locations_eta_chk check (eta_minutes is null or eta_minutes between 0 and 999),
  constraint locations_occupied_chk check (occupied_seats between 0 and 99),
  constraint locations_capacity_chk check (capacity between 0 and 99)
);

-- COMMISSION REQUESTS
create table if not exists public.commission_requests (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  requested_at timestamptz not null default now(),
  status public.commission_request_status not null default 'pendiente',
  commission_amount numeric(10,2) not null default 0,
  total_recaudado numeric(10,2) not null default 0,
  commission_pct numeric(5,2) not null default 15.00,
  admin_confirmed_at timestamptz,
  driver_received_at timestamptz,
  constraint commission_req_amount_chk check (commission_amount >= 0),
  constraint commission_req_total_chk check (total_recaudado >= 0),
  constraint commission_req_pct_chk check (commission_pct between 0 and 100)
);

create index if not exists idx_commission_req_driver on public.commission_requests(driver_id);
create index if not exists idx_commission_req_status on public.commission_requests(status);

-- DRIVER COMMISSIONS
create table if not exists public.driver_commissions (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  day date not null,
  recaudado numeric(10,2) not null default 0,
  comision numeric(10,2) not null default 0,
  estado text not null default 'Pagado',
  request_id uuid references public.commission_requests(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint commissions_recaudado_chk check (recaudado >= 0),
  constraint commissions_comision_chk check (comision >= 0)
);

create index if not exists idx_commissions_driver_day on public.driver_commissions(driver_id, day);

-- SUPPORT TICKETS
create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles(id) on delete set null,
  description text not null,
  device_info text,
  app_version text,
  created_at timestamptz not null default now(),
  constraint support_desc_chk check (length(trim(description)) > 0)
);

create index if not exists idx_support_profile_created on public.support_tickets(profile_id, created_at);

-- 5) TRIGGERS DE NEGOCIO

-- Auto-crear profile al registrarse
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'passenger')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Recalcular rating del conductor
create or replace function public.recompute_driver_rating()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_driver_id uuid;
begin
  v_driver_id = new.driver_id;
  if v_driver_id is null then return new; end if;
  update public.drivers d
  set rating_count = r.cnt, rating_avg = r.avg, updated_at = now()
  from (
    select driver_id, count(*)::int as cnt, round(avg(stars)::numeric, 2) as avg
    from public.ratings where driver_id = v_driver_id group by driver_id
  ) r
  where d.id = r.driver_id;
  return new;
end;
$$;

drop trigger if exists trg_ratings_recompute_driver on public.ratings;
create trigger trg_ratings_recompute_driver
after insert on public.ratings
for each row execute function public.recompute_driver_rating();

-- 6) RLS

alter table public.profiles enable row level security;
alter table public.routes enable row level security;
alter table public.pickup_points enable row level security;
alter table public.drivers enable row level security;
alter table public.vehicles enable row level security;
alter table public.trips enable row level security;
alter table public.reservations enable row level security;
alter table public.reservation_companions enable row level security;
alter table public.manifests enable row level security;
alter table public.manifest_entries enable row level security;
alter table public.payments enable row level security;
alter table public.payment_methods enable row level security;
alter table public.driver_payout_requests enable row level security;
alter table public.driver_payouts enable row level security;
alter table public.trip_messages enable row level security;
alter table public.driver_group_messages enable row level security;
alter table public.news_posts enable row level security;
alter table public.ratings enable row level security;
alter table public.driver_locations enable row level security;
alter table public.commission_requests enable row level security;
alter table public.driver_commissions enable row level security;
alter table public.support_tickets enable row level security;

-- PROFILES
drop policy if exists "profiles_select" on public.profiles;
drop policy if exists "profiles self read" on public.profiles;
drop policy if exists "profiles admin read" on public.profiles;
drop policy if exists "profiles driver read passengers" on public.profiles;
create policy "profiles_select" on public.profiles for select to authenticated
using (id = auth.uid() or public.is_admin() or exists (
  select 1 from public.reservations r
  join public.trips t on t.id = r.trip_id
  join public.drivers d on d.id = t.driver_id
  where r.passenger_profile_id = public.profiles.id and d.profile_id = auth.uid()
));

drop policy if exists "profiles_insert" on public.profiles;
drop policy if exists "profiles self write" on public.profiles;
create policy "profiles_insert" on public.profiles for insert to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update" on public.profiles;
drop policy if exists "profiles self update" on public.profiles;
create policy "profiles_update" on public.profiles for update to authenticated
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

-- ROUTES
drop policy if exists "routes_select" on public.routes;
drop policy if exists "routes public read" on public.routes;
create policy "routes_select" on public.routes for select to anon, authenticated using (true);

drop policy if exists "routes_admin_insert" on public.routes;
drop policy if exists "routes_admin_update" on public.routes;
drop policy if exists "routes_admin_delete" on public.routes;
create policy "routes_admin_insert" on public.routes for insert to authenticated with check (public.is_admin());
create policy "routes_admin_update" on public.routes for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "routes_admin_delete" on public.routes for delete to authenticated using (public.is_admin());

-- PICKUP POINTS
drop policy if exists "pickup_select" on public.pickup_points;
create policy "pickup_select" on public.pickup_points for select to anon, authenticated using (true);
drop policy if exists "pickup_admin_insert" on public.pickup_points;
drop policy if exists "pickup_admin_update" on public.pickup_points;
drop policy if exists "pickup_admin_delete" on public.pickup_points;
create policy "pickup_admin_insert" on public.pickup_points for insert to authenticated with check (public.is_admin());
create policy "pickup_admin_update" on public.pickup_points for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "pickup_admin_delete" on public.pickup_points for delete to authenticated using (public.is_admin());

-- DRIVERS
drop policy if exists "drivers_select" on public.drivers;
drop policy if exists "drivers self read" on public.drivers;
drop policy if exists "drivers public read" on public.drivers;
create policy "drivers_select" on public.drivers for select to authenticated using (true);

drop policy if exists "drivers_admin_write" on public.drivers;
create policy "drivers_admin_write" on public.drivers for insert to authenticated
with check (public.is_admin());

drop policy if exists "drivers_self_update" on public.drivers;
drop policy if exists "drivers self update" on public.drivers;
create policy "drivers_self_update" on public.drivers for update to authenticated
using (profile_id = auth.uid() or public.is_admin())
with check (profile_id = auth.uid() or public.is_admin());

-- VEHICLES
drop policy if exists "vehicles_select" on public.vehicles;
create policy "vehicles_select" on public.vehicles for select to authenticated using (true);
drop policy if exists "vehicles_admin_insert" on public.vehicles;
drop policy if exists "vehicles_admin_update" on public.vehicles;
drop policy if exists "vehicles_admin_delete" on public.vehicles;
create policy "vehicles_admin_insert" on public.vehicles for insert to authenticated with check (public.is_admin());
create policy "vehicles_admin_update" on public.vehicles for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "vehicles_admin_delete" on public.vehicles for delete to authenticated using (public.is_admin());

-- TRIPS
drop policy if exists "trips_admin_select" on public.trips;
drop policy if exists "trips_driver_select" on public.trips;
drop policy if exists "trips_passenger_select" on public.trips;
drop policy if exists "trips authenticated read" on public.trips;
create policy "trips_select" on public.trips for select to authenticated using (
  public.is_admin()
  or exists (select 1 from public.drivers d where d.id = trips.driver_id and d.profile_id = auth.uid())
  or exists (select 1 from public.reservations r where r.trip_id = trips.id and r.passenger_profile_id = auth.uid())
);

drop policy if exists "trips_admin_insert" on public.trips;
drop policy if exists "trips_admin_update" on public.trips;
drop policy if exists "trips_admin_delete" on public.trips;
drop policy if exists "trips authenticated insert" on public.trips;
create policy "trips_admin_insert" on public.trips for insert to authenticated with check (public.is_admin());
create policy "trips_admin_update" on public.trips for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "trips_admin_delete" on public.trips for delete to authenticated using (public.is_admin());

-- RESERVATIONS
drop policy if exists "reservations_passenger_select" on public.reservations;
drop policy if exists "reservations_driver_select" on public.reservations;
drop policy if exists "reservations passenger read" on public.reservations;
drop policy if exists "reservations authenticated read" on public.reservations;
create policy "reservations_select" on public.reservations for select to authenticated
using (
  public.is_admin()
  or passenger_profile_id = auth.uid()
  or exists (
    select 1 from public.trips t join public.drivers d on d.id = t.driver_id
    where t.id = reservations.trip_id and d.profile_id = auth.uid()
  )
);

drop policy if exists "reservations_passenger_insert" on public.reservations;
drop policy if exists "reservations passenger insert" on public.reservations;
create policy "reservations_passenger_insert" on public.reservations for insert to authenticated
with check (passenger_profile_id = auth.uid());

drop policy if exists "reservations_passenger_update" on public.reservations;
create policy "reservations_passenger_update" on public.reservations for update to authenticated
using (passenger_profile_id = auth.uid() or public.is_admin())
with check (passenger_profile_id = auth.uid() or public.is_admin());

-- COMPANIONS
drop policy if exists "companions_select" on public.reservation_companions;
create policy "companions_select" on public.reservation_companions for select to authenticated
using (public.is_admin() or exists (
  select 1 from public.reservations r
  where r.id = reservation_companions.reservation_id and r.passenger_profile_id = auth.uid()
));
drop policy if exists "companions_insert" on public.reservation_companions;
drop policy if exists "companions_update" on public.reservation_companions;
drop policy if exists "companions_delete" on public.reservation_companions;
create policy "companions_insert" on public.reservation_companions for insert to authenticated
with check (public.is_admin() or exists (
  select 1 from public.reservations r
  where r.id = reservation_companions.reservation_id and r.passenger_profile_id = auth.uid()
));
create policy "companions_update" on public.reservation_companions for update to authenticated
using (public.is_admin() or exists (
  select 1 from public.reservations r
  where r.id = reservation_companions.reservation_id and r.passenger_profile_id = auth.uid()
))
with check (public.is_admin() or exists (
  select 1 from public.reservations r
  where r.id = reservation_companions.reservation_id and r.passenger_profile_id = auth.uid()
));
create policy "companions_delete" on public.reservation_companions for delete to authenticated
using (public.is_admin() or exists (
  select 1 from public.reservations r
  where r.id = reservation_companions.reservation_id and r.passenger_profile_id = auth.uid()
));

-- MANIFESTS
drop policy if exists "manifests_select" on public.manifests;
create policy "manifests_select" on public.manifests for select to authenticated
using (public.is_admin() or (public.is_driver() and exists (
  select 1 from public.trips t join public.drivers d on d.id = t.driver_id
  where t.id = manifests.trip_id and d.profile_id = auth.uid()
)));
drop policy if exists "manifests_admin_insert" on public.manifests;
drop policy if exists "manifests_admin_update" on public.manifests;
drop policy if exists "manifests_admin_delete" on public.manifests;
create policy "manifests_admin_insert" on public.manifests for insert to authenticated with check (public.is_admin());
drop policy if exists "manifests_driver_insert" on public.manifests;
create policy "manifests_driver_insert" on public.manifests for insert to authenticated
with check (exists (
  select 1 from public.trips t join public.drivers d on d.id = t.driver_id
  where t.id = manifests.trip_id and d.profile_id = auth.uid()
    and t.status in ('esperando', 'en_ruta', 'lleno')
));
create policy "manifests_admin_update" on public.manifests for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "manifests_admin_delete" on public.manifests for delete to authenticated using (public.is_admin());

-- MANIFEST ENTRIES
drop policy if exists "entries_select" on public.manifest_entries;
create policy "entries_select" on public.manifest_entries for select to authenticated
using (public.is_admin() or passenger_profile_id = auth.uid() or (public.is_driver() and exists (
  select 1 from public.manifests m join public.trips t on t.id = m.trip_id
  join public.drivers d on d.id = t.driver_id
  where m.id = manifest_entries.manifest_id and d.profile_id = auth.uid()
)));
drop policy if exists "entries_driver_insert" on public.manifest_entries;
drop policy if exists "entries_driver_update" on public.manifest_entries;
drop policy if exists "entries_driver_delete" on public.manifest_entries;
create policy "entries_driver_insert" on public.manifest_entries for insert to authenticated
with check (public.is_admin() or (public.is_driver() and exists (
  select 1 from public.manifests m join public.trips t on t.id = m.trip_id
  join public.drivers d on d.id = t.driver_id
  where m.id = manifest_entries.manifest_id and d.profile_id = auth.uid()
)));
create policy "entries_driver_update" on public.manifest_entries for update to authenticated
using (public.is_admin() or (public.is_driver() and exists (
  select 1 from public.manifests m join public.trips t on t.id = m.trip_id
  join public.drivers d on d.id = t.driver_id
  where m.id = manifest_entries.manifest_id and d.profile_id = auth.uid()
)))
with check (public.is_admin() or (public.is_driver() and exists (
  select 1 from public.manifests m join public.trips t on t.id = m.trip_id
  join public.drivers d on d.id = t.driver_id
  where m.id = manifest_entries.manifest_id and d.profile_id = auth.uid()
)));
create policy "entries_driver_delete" on public.manifest_entries for delete to authenticated
using (public.is_admin() or (public.is_driver() and exists (
  select 1 from public.manifests m join public.trips t on t.id = m.trip_id
  join public.drivers d on d.id = t.driver_id
  where m.id = manifest_entries.manifest_id and d.profile_id = auth.uid()
)));

-- PAYMENTS
drop policy if exists "payments_select" on public.payments;
drop policy if exists "payments passenger read" on public.payments;
create policy "payments_select" on public.payments for select to authenticated
using (public.is_admin() or exists (
  select 1 from public.reservations r
  where r.id = payments.reservation_id and r.passenger_profile_id = auth.uid()
));
drop policy if exists "payments_insert" on public.payments;
drop policy if exists "payments passenger insert" on public.payments;
create policy "payments_insert" on public.payments for insert to authenticated
with check (exists (
  select 1 from public.reservations r
  where r.id = payments.reservation_id and r.passenger_profile_id = auth.uid()
));

-- PAYMENT METHODS
drop policy if exists "payment_methods_select" on public.payment_methods;
create policy "payment_methods_select" on public.payment_methods for select to authenticated
using (profile_id = auth.uid() or public.is_admin());
drop policy if exists "payment_methods_insert" on public.payment_methods;
drop policy if exists "payment_methods_update" on public.payment_methods;
drop policy if exists "payment_methods_delete" on public.payment_methods;
create policy "payment_methods_insert" on public.payment_methods for insert to authenticated with check (profile_id = auth.uid() or public.is_admin());
create policy "payment_methods_update" on public.payment_methods for update to authenticated using (profile_id = auth.uid() or public.is_admin()) with check (profile_id = auth.uid() or public.is_admin());
create policy "payment_methods_delete" on public.payment_methods for delete to authenticated using (profile_id = auth.uid() or public.is_admin());

-- DRIVER PAYOUT REQUESTS
drop policy if exists "payout requests self read" on public.driver_payout_requests;
create policy "payout_requests_select" on public.driver_payout_requests for select to authenticated
using (profile_id = auth.uid() or public.is_admin());
drop policy if exists "payout requests self insert" on public.driver_payout_requests;
create policy "payout_requests_insert" on public.driver_payout_requests for insert to authenticated
with check (profile_id = auth.uid());

-- DRIVER PAYOUTS
drop policy if exists "payouts self read" on public.driver_payouts;
create policy "payouts_select" on public.driver_payouts for select to authenticated
using (profile_id = auth.uid() or public.is_admin());

-- TRIP MESSAGES
drop policy if exists "trip_messages_select" on public.trip_messages;
drop policy if exists "trip messages participant read" on public.trip_messages;
create policy "trip_messages_select" on public.trip_messages for select to authenticated
using (public.is_admin()
  or exists (select 1 from public.reservations r where r.trip_id = trip_messages.trip_id and r.passenger_profile_id = auth.uid())
  or exists (select 1 from public.trips t join public.drivers d on d.id = t.driver_id where t.id = trip_messages.trip_id and d.profile_id = auth.uid())
);
drop policy if exists "trip_messages_insert" on public.trip_messages;
create policy "trip_messages_insert" on public.trip_messages for insert to authenticated
with check (sender_profile_id = auth.uid() or public.is_admin());

-- GROUP MESSAGES
drop policy if exists "group_messages_select" on public.driver_group_messages;
create policy "group_messages_select" on public.driver_group_messages for select to authenticated using (true);
drop policy if exists "group_messages_insert" on public.driver_group_messages;
drop policy if exists "group_messages_update" on public.driver_group_messages;
drop policy if exists "group_messages_delete" on public.driver_group_messages;
create policy "group_messages_insert" on public.driver_group_messages for insert to authenticated with check (public.is_admin() or public.is_driver());
create policy "group_messages_update" on public.driver_group_messages for update to authenticated using (public.is_admin() or public.is_driver()) with check (public.is_admin() or public.is_driver());
create policy "group_messages_delete" on public.driver_group_messages for delete to authenticated using (public.is_admin() or public.is_driver());

-- NEWS
drop policy if exists "news_select" on public.news_posts;
drop policy if exists "news public read" on public.news_posts;
create policy "news_select" on public.news_posts for select to authenticated using (true);
drop policy if exists "news_insert" on public.news_posts;
drop policy if exists "news_update" on public.news_posts;
drop policy if exists "news_delete" on public.news_posts;
drop policy if exists "news driver write" on public.news_posts;
create policy "news_insert" on public.news_posts for insert to authenticated with check (public.is_admin() or public.is_driver());
create policy "news_update" on public.news_posts for update to authenticated using (public.is_admin() or public.is_driver()) with check (public.is_admin() or public.is_driver());
create policy "news_delete" on public.news_posts for delete to authenticated using (public.is_admin() or public.is_driver());

-- RATINGS
drop policy if exists "ratings_select" on public.ratings;
create policy "ratings_select" on public.ratings for select to authenticated using (true);
drop policy if exists "ratings_insert" on public.ratings;
create policy "ratings_insert" on public.ratings for insert to authenticated
with check (rater_profile_id = auth.uid());

-- DRIVER LOCATIONS
drop policy if exists "locations_select" on public.driver_locations;
create policy "locations_select" on public.driver_locations for select to authenticated
using (public.is_admin() or (public.is_driver() and exists (
  select 1 from public.drivers d where d.id = driver_locations.driver_id and d.profile_id = auth.uid()
)) or exists (
  select 1 from public.reservations r
  join public.trips t on t.id = r.trip_id
  where t.driver_id = driver_locations.driver_id
    and r.passenger_profile_id = auth.uid()
    and r.status = 'activa'
));
drop policy if exists "locations_insert" on public.driver_locations;
drop policy if exists "locations_update" on public.driver_locations;
create policy "locations_insert" on public.driver_locations for insert to authenticated
with check (public.is_driver() and exists (
  select 1 from public.drivers d where d.id = driver_locations.driver_id and d.profile_id = auth.uid()
));
create policy "locations_update" on public.driver_locations for update to authenticated
using (public.is_driver() and exists (
  select 1 from public.drivers d where d.id = driver_locations.driver_id and d.profile_id = auth.uid()
))
with check (public.is_driver() and exists (
  select 1 from public.drivers d where d.id = driver_locations.driver_id and d.profile_id = auth.uid()
));

-- COMMISSIONS
drop policy if exists "commission_req_select" on public.commission_requests;
create policy "commission_req_select" on public.commission_requests for select to authenticated
using (public.is_admin() or exists (
  select 1 from public.drivers d where d.id = commission_requests.driver_id and d.profile_id = auth.uid()
));
drop policy if exists "commission_req_insert" on public.commission_requests;
drop policy if exists "commission_req_update" on public.commission_requests;
drop policy if exists "commission_req_delete" on public.commission_requests;
create policy "commission_req_insert" on public.commission_requests for insert to authenticated with check (public.is_admin());
create policy "commission_req_update" on public.commission_requests for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "commission_req_delete" on public.commission_requests for delete to authenticated using (public.is_admin());

drop policy if exists "commissions_select" on public.driver_commissions;
create policy "commissions_select" on public.driver_commissions for select to authenticated
using (public.is_admin() or exists (
  select 1 from public.drivers d where d.id = driver_commissions.driver_id and d.profile_id = auth.uid()
));
drop policy if exists "commissions_insert" on public.driver_commissions;
drop policy if exists "commissions_update" on public.driver_commissions;
drop policy if exists "commissions_delete" on public.driver_commissions;
create policy "commissions_insert" on public.driver_commissions for insert to authenticated with check (public.is_admin());
create policy "commissions_update" on public.driver_commissions for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "commissions_delete" on public.driver_commissions for delete to authenticated using (public.is_admin());

-- SUPPORT
drop policy if exists "support_select" on public.support_tickets;
create policy "support_select" on public.support_tickets for select to authenticated
using (public.is_admin() or profile_id = auth.uid());
drop policy if exists "support_insert" on public.support_tickets;
create policy "support_insert" on public.support_tickets for insert to authenticated
with check (profile_id = auth.uid());

-- 7) SEEDS
insert into public.routes (name, from_label, to_label)
values
  ('San Isidro → Chosica', 'San Isidro', 'Chosica'),
  ('Chosica → San Isidro', 'Chosica', 'San Isidro')
on conflict do nothing;
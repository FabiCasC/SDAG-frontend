-- RF-011/074/060: votos salida anticipada + RF-107: archivado de chats

alter table public.trips
  add column if not exists votos_salida integer not null default 0;

alter table public.trips
  add constraint trips_votos_salida_chk check (votos_salida >= 0);

alter table public.reservations
  add column if not exists voted_early_departure boolean not null default false;

alter table public.trip_messages
  add column if not exists message_status text not null default 'activo';

alter table public.trip_messages
  drop constraint if exists trip_messages_status_chk;

alter table public.trip_messages
  add constraint trip_messages_status_chk check (message_status in ('activo', 'archivado'));

create index if not exists idx_trip_messages_status
  on public.trip_messages(trip_id, message_status, created_at desc);

-- Conductor puede actualizar su viaje activo (status, votos)
drop policy if exists "trips_driver_update" on public.trips;
create policy "trips_driver_update" on public.trips
  for update to authenticated
  using (
    exists (
      select 1 from public.drivers d
      where d.id = trips.driver_id and d.profile_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.drivers d
      where d.id = trips.driver_id and d.profile_id = auth.uid()
    )
  );

-- Pasajero puede actualizar su reserva (cancelación / voto)
drop policy if exists "reservations_passenger_update" on public.reservations;
create policy "reservations_passenger_update" on public.reservations
  for update to authenticated
  using (passenger_profile_id = auth.uid())
  with check (passenger_profile_id = auth.uid());

-- Pasajero puede actualizar pago de su reserva (reembolso)
drop policy if exists "payments_passenger_update" on public.payments;
create policy "payments_passenger_update" on public.payments
  for update to authenticated
  using (
    exists (
      select 1 from public.reservations r
      where r.id = payments.reservation_id and r.passenger_profile_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.reservations r
      where r.id = payments.reservation_id and r.passenger_profile_id = auth.uid()
    )
  );

-- Archivar mensajes al completar viaje (conductor)
drop policy if exists "trip_messages_update" on public.trip_messages;
create policy "trip_messages_update" on public.trip_messages
  for update to authenticated
  using (
    exists (
      select 1 from public.trips t
      join public.drivers d on d.id = t.driver_id
      where t.id = trip_messages.trip_id and d.profile_id = auth.uid()
    )
    or public.is_admin()
  )
  with check (
    exists (
      select 1 from public.trips t
      join public.drivers d on d.id = t.driver_id
      where t.id = trip_messages.trip_id and d.profile_id = auth.uid()
    )
    or public.is_admin()
  );

-- Voto de salida anticipada (RF-011)
create or replace function public.register_early_departure_vote(p_trip_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_trip record;
  v_reservation record;
  v_passenger_count int;
  v_votos int;
  v_threshold int;
  v_wait_minutes numeric;
begin
  if v_user is null then
    return jsonb_build_object('ok', false, 'error', 'Sesión inválida');
  end if;

  select * into v_trip from public.trips where id = p_trip_id for update;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'Viaje no encontrado');
  end if;

  if v_trip.status <> 'esperando' then
    return jsonb_build_object('ok', false, 'error', 'El viaje ya no está en espera');
  end if;

  v_wait_minutes := extract(epoch from (now() - v_trip.created_at)) / 60.0;
  if v_wait_minutes < 10 then
    return jsonb_build_object('ok', false, 'error', 'Deben transcurrir al menos 10 minutos de espera');
  end if;

  select * into v_reservation
  from public.reservations
  where trip_id = p_trip_id
    and passenger_profile_id = v_user
    and status = 'activa'
  for update;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'No tienes reserva activa en este viaje');
  end if;

  if v_reservation.voted_early_departure then
    return jsonb_build_object('ok', false, 'error', 'Ya registraste tu voto');
  end if;

  update public.reservations
  set voted_early_departure = true
  where id = v_reservation.id;

  update public.trips
  set votos_salida = votos_salida + 1
  where id = p_trip_id
  returning votos_salida into v_votos;

  select count(*) into v_passenger_count
  from public.reservations
  where trip_id = p_trip_id and status in ('activa', 'completada');

  v_threshold := ceil(v_passenger_count * 0.5);

  if v_votos >= v_threshold and v_passenger_count > 0 then
    update public.trips
    set status = 'en_ruta', started_at = coalesce(started_at, now())
    where id = p_trip_id;

    update public.drivers
    set estado = 'en_ruta'
    where id = v_trip.driver_id;

    return jsonb_build_object(
      'ok', true,
      'votos', v_votos,
      'total', v_passenger_count,
      'departure_authorized', true
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'votos', v_votos,
    'total', v_passenger_count,
    'departure_authorized', false
  );
end;
$$;

grant execute on function public.register_early_departure_vote(uuid) to authenticated;

-- Permite a pasajeros con reserva activa leer la ubicación de su conductor.
drop policy if exists "locations_passenger_active_reservation" on public.driver_locations;
create policy "locations_passenger_active_reservation" on public.driver_locations
for select to authenticated
using (
  exists (
    select 1
    from public.reservations r
    join public.trips t on t.id = r.trip_id
    where t.driver_id = driver_locations.driver_id
      and r.passenger_profile_id = auth.uid()
      and r.status = 'activa'
  )
);

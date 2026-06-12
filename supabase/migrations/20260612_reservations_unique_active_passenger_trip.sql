-- Evita reservas duplicadas activas del mismo pasajero en el mismo viaje.
create unique index if not exists reservations_unique_active_passenger_trip
on public.reservations (trip_id, passenger_profile_id)
where status = 'activa';

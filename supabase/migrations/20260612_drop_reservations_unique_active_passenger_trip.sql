-- Permite múltiples reservas activas del mismo pasajero en el mismo viaje.
drop index if exists public.reservations_unique_active_passenger_trip;

-- Agrega 'cancelado' al enum boarding_status (si aún no existe).
alter type public.boarding_status add value if not exists 'cancelado';

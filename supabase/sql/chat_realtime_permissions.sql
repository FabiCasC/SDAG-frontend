-- Ejecutar en Supabase SQL Editor (o aplicar migraciones del proyecto).
-- Permisos y Realtime para chats conductor/admin.

grant select, insert on public.driver_group_messages to authenticated;
grant select, insert, delete on public.trip_messages to authenticated;

do $$
begin
  alter publication supabase_realtime add table public.driver_group_messages;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.trip_messages;
exception
  when duplicate_object then null;
end $$;

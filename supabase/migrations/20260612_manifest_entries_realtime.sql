-- Notificaciones en tiempo real de abordaje para pasajeros (manifest_entries).
-- Requerido para que reserva_activa_screen / confirmacion_screen detecten abordaje al instante.
-- Idempotente: ignora si la tabla ya está en la publicación.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'manifest_entries'
  ) then
    alter publication supabase_realtime add table public.manifest_entries;
  end if;
end $$;

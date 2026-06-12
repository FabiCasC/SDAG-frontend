-- Permite al conductor crear el manifiesto de su viaje activo (p. ej. al escanear QR).
drop policy if exists "manifests_driver_insert" on public.manifests;
create policy "manifests_driver_insert" on public.manifests
for insert to authenticated
with check (
  exists (
    select 1
    from public.trips t
    join public.drivers d on d.id = t.driver_id
    where t.id = manifests.trip_id
      and d.profile_id = auth.uid()
      and t.status in ('esperando', 'en_ruta', 'lleno')
  )
);

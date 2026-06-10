-- Chat conductor–pasajero: columnas alineadas con la app + Realtime + borrado por conductor/admin

alter table public.trip_messages add column if not exists passenger_id uuid references public.profiles(id) on delete set null;
alter table public.trip_messages add column if not exists message text;
alter table public.trip_messages add column if not exists sender_id uuid references public.profiles(id) on delete set null;

update public.trip_messages set message = body where message is null;
update public.trip_messages set sender_id = sender_profile_id where sender_id is null and sender_profile_id is not null;

alter table public.trip_messages drop constraint if exists trip_messages_body_chk;

-- Permite insertar solo `message` desde la app; `body` sigue existiendo por compatibilidad.
alter table public.trip_messages alter column body drop not null;

alter table public.trip_messages add constraint trip_messages_message_nonempty_chk
  check (length(trim(coalesce(message, body, ''))) > 0);

grant select, insert, delete on public.trip_messages to authenticated;

drop policy if exists "trip_messages_delete" on public.trip_messages;
create policy "trip_messages_delete" on public.trip_messages for delete to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.trips t
    join public.drivers d on d.id = t.driver_id
    where t.id = trip_messages.trip_id
      and d.profile_id = auth.uid()
  )
);

do $$
begin
  alter publication supabase_realtime add table public.trip_messages;
exception
  when duplicate_object then null;
end $$;

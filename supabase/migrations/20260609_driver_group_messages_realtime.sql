alter table public.driver_group_messages
  add column if not exists sender_id uuid references public.profiles(id) on delete set null;

alter table public.driver_group_messages
  add column if not exists message text;

alter table public.driver_group_messages
  add column if not exists sender_role text default 'driver';

update public.driver_group_messages
set
  message = coalesce(message, body),
  sender_role = coalesce(sender_role, 'driver')
where message is null or sender_role is null;

grant select, insert on public.driver_group_messages to authenticated;

alter publication supabase_realtime add table public.driver_group_messages;

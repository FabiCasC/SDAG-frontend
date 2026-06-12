-- Renombra la columna boarding → boarding_status en manifest_entries (si aún existe el nombre antiguo).
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'manifest_entries'
      and column_name = 'boarding'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'manifest_entries'
      and column_name = 'boarding_status'
  ) then
    alter table public.manifest_entries rename column boarding to boarding_status;
  end if;
end $$;

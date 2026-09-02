-- ============================================================
-- QUALIFIED PROVEEDORES — exclusión "a la carta": ahora puedes
-- excluir solo los km, solo las horas, solo los días, o cualquier
-- combinación (antes era todo o nada). Sustituye a la columna
-- excluded_from_calc del script anterior (daily-entries-exclusion.sql).
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='daily_entries' and column_name='excluded_from_calc'
  ) then
    alter table public.daily_entries rename column excluded_from_calc to exclude_days;
  end if;
end $$;

alter table public.daily_entries
  add column if not exists exclude_days boolean not null default false;
alter table public.daily_entries
  add column if not exists exclude_km boolean not null default false;
alter table public.daily_entries
  add column if not exists exclude_hours boolean not null default false;

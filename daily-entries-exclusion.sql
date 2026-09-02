-- ============================================================
-- QUALIFIED PROVEEDORES — excluir un día del cálculo normal
-- (Plaza) y pagar en su lugar un importe manual, para jornadas
-- parciales (p. ej. 6h en vez de la jornada completa).
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

alter table public.daily_entries
  add column if not exists excluded_from_calc boolean not null default false;
alter table public.daily_entries
  add column if not exists manual_amount numeric not null default 0;

alter table public.weekly_entries
  add column if not exists manual_amount numeric not null default 0;

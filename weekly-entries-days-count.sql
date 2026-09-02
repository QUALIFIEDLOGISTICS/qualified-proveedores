-- ============================================================
-- QUALIFIED PROVEEDORES — un día con importe manual cuenta como
-- jornada trabajada, aunque esté excluido del €/día (para que la
-- semana muestre los días realmente trabajados).
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

alter table public.weekly_entries
  add column if not exists days_count integer not null default 0;

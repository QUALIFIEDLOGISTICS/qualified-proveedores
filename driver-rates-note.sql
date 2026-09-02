-- ============================================================
-- QUALIFIED PROVEEDORES — campo de observaciones al crear/editar
-- una tarifa de Plaza (driver_rates).
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

alter table public.driver_rates
  add column if not exists note text;

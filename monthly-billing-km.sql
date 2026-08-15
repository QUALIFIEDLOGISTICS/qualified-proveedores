-- ============================================================
-- QUALIFIED PROVEEDORES — km realizados en la facturación mensual
-- de Piso Móvil, para calcular el €/km.
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

alter table public.monthly_billing_entries
  add column if not exists km numeric not null default 0;

-- ============================================================
-- QUALIFIED PROVEEDORES — ¿esta tarifa lleva indexación o no?
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

-- Por defecto TRUE para no cambiar el comportamiento de las tarifas
-- ya existentes (hasta ahora la indexación mensual se aplicaba
-- siempre, a todo el mundo).
alter table public.driver_rates
  add column if not exists has_indexation boolean not null default true;

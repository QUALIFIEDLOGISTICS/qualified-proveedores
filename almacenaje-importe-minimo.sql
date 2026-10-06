-- ============================================================
-- QUALIFIED PROVEEDORES — importe mínimo en las tarifas de almacenaje
-- Cada línea de tarifa puede llevar un importe mínimo por albarán:
-- si precio x cantidad sale por debajo, se cobra ese mínimo (p. ej.
-- salidas a 3 €/palet con mínimo de 10 € → 2 palets = 6 € → se cobran 10 €).
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

alter table public.almacenaje_tarifas
  add column if not exists importe_minimo numeric;

notify pgrst, 'reload schema';

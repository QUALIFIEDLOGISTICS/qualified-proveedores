-- ============================================================
-- QUALIFIED PROVEEDORES — subtipo fijo por producto de almacenaje
-- Cada producto puede llevar su subtipo ya definido (p. ej. "Palet
-- Europeo" → Europeo): al elegirlo en una tarifa de almacenaje, el
-- subtipo se rellena solo y no se puede cambiar.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

alter table public.almacenaje_productos
  add column if not exists subtipo_valor text;

notify pgrst, 'reload schema';

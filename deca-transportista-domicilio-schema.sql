-- ============================================================
-- QUALIFIED PROVEEDORES — DeCA: domicilio del transportista
-- efectivo, para que salga en la casilla 2 del PDF igual que el
-- del cargador contractual en la casilla 1.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

alter table public.deca_documents add column if not exists transportista_domicilio text;

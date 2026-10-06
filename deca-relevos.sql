-- ============================================================
-- QUALIFIED PROVEEDORES — relevo de tractora en el DeCA
-- Cuando la tractora cambia durante el transporte (el remolque es el
-- mismo), el DeCA guarda la lista de relevos: cada uno con la matrícula
-- de la nueva tractora y, si es de otra empresa, su transportista.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

alter table public.deca_documents
  add column if not exists relevos jsonb;

notify pgrst, 'reload schema';

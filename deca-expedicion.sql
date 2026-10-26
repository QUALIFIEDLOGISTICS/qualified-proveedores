-- ============================================================
-- QUALIFIED PROVEEDORES — DeCA vinculado a una expedición de Almacén (SGA)
-- Al generar un DeCA desde Control Stock SGA → Expediciones queda guardado a qué expedición pertenece.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
alter table public.deca_documents add column if not exists albaran_id uuid references public.sga_albaranes(id) on delete set null;
create index if not exists deca_documents_albaran_idx on public.deca_documents (albaran_id);
notify pgrst, 'reload schema';

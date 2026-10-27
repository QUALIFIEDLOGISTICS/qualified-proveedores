-- ============================================================
-- QUALIFIED PROVEEDORES — Orden de carga vinculada a una expedición de Almacén (SGA)
-- Al generar una orden de carga desde Control Stock SGA → Expediciones queda guardado a qué expedición pertenece.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
alter table public.ordenes_carga add column if not exists albaran_id uuid references public.sga_albaranes(id) on delete set null;
create index if not exists ordenes_carga_albaran_idx on public.ordenes_carga (albaran_id);
notify pgrst, 'reload schema';

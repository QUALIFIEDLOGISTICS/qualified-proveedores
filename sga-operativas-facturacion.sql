-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Operativas: marcar si están facturadas o pendientes
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
alter table public.sga_operativas_realizadas add column if not exists facturada boolean not null default false;
alter table public.sga_operativas_realizadas add column if not exists facturada_at timestamptz;
alter table public.sga_operativas_realizadas add column if not exists factura text;
notify pgrst, 'reload schema';

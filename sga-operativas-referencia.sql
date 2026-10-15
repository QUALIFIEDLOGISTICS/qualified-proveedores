-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Operativas: nº de albarán o contenedor
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
alter table public.sga_operativas_realizadas add column if not exists referencia text;
notify pgrst, 'reload schema';

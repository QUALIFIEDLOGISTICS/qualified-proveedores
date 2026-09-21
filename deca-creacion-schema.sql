-- ============================================================
-- QUALIFIED PROVEEDORES — DeCA: fecha y hora de creación del
-- documento (con segundos), que se escriben a mano en "Información
-- de creación" y salen impresas en el PDF.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

alter table public.deca_documents add column if not exists creacion_fecha date;
alter table public.deca_documents add column if not exists creacion_hora time;

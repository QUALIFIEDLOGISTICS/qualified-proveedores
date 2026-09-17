-- ============================================================
-- QUALIFIED PROVEEDORES — separa la matrícula del DeCA en tractora
-- y remolque (antes era un único campo "matrícula del vehículo").
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores
-- (incluido deca-schema.sql).
-- ============================================================

alter table public.deca_documents rename column matricula to matricula_tractora;
alter table public.deca_documents add column if not exists matricula_remolque text;

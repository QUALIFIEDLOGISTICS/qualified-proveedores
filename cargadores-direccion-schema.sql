-- ============================================================
-- QUALIFIED PROVEEDORES — desglosa el domicilio del cargador
-- contractual en Calle 1 / Calle 2 / Código postal / Ciudad /
-- Provincia / País, en vez de un único campo de texto libre.
-- Migra lo que hubiera en "domicilio" a "calle1" para no perder
-- nada, y elimina la columna antigua.
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores
-- (incluido deca-cargadores-schema.sql).
-- ============================================================

alter table public.cargadores_contractuales add column if not exists calle1 text;
alter table public.cargadores_contractuales add column if not exists calle2 text;
alter table public.cargadores_contractuales add column if not exists codigo_postal text;
alter table public.cargadores_contractuales add column if not exists ciudad text;
alter table public.cargadores_contractuales add column if not exists provincia text;
alter table public.cargadores_contractuales add column if not exists pais text;

update public.cargadores_contractuales set calle1 = domicilio where domicilio is not null and calle1 is null;
alter table public.cargadores_contractuales drop column if exists domicilio;

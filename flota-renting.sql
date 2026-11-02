-- ============================================================
-- QUALIFIED PROVEEDORES — Flota: propiedad del vehículo y contrato de renting / leasing
-- Régimen (en propiedad, renting o leasing), empresa, nº de contrato, inicio y fin,
-- cuota mensual, cuota final, km incluidos al año y notas.
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
alter table public.flota add column if not exists regimen text not null default 'propiedad';
alter table public.flota add column if not exists renting_empresa text;
alter table public.flota add column if not exists renting_contrato text;
alter table public.flota add column if not exists renting_inicio date;
alter table public.flota add column if not exists renting_fin date;
alter table public.flota add column if not exists renting_cuota numeric(10, 2);
alter table public.flota add column if not exists renting_cuota_final numeric(10, 2);
alter table public.flota add column if not exists renting_km integer;
alter table public.flota add column if not exists renting_notas text;

notify pgrst, 'reload schema';

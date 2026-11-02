-- ============================================================
-- QUALIFIED PROVEEDORES — Flota: datos del seguro de cada vehículo
-- Aseguradora, nº de póliza, cobertura, prima anual, teléfono y notas.
-- (La fecha de vencimiento del seguro ya existía: seguro_vence.)
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
alter table public.flota add column if not exists seguro_aseguradora text;
alter table public.flota add column if not exists seguro_poliza text;
alter table public.flota add column if not exists seguro_cobertura text;
alter table public.flota add column if not exists seguro_prima numeric(10, 2);
alter table public.flota add column if not exists seguro_telefono text;
alter table public.flota add column if not exists seguro_notas text;

notify pgrst, 'reload schema';

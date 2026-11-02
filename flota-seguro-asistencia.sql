-- ============================================================
-- QUALIFIED PROVEEDORES — Flota: seguro → franquicia, asistencia en carretera y correo
-- Importe de la franquicia, si tiene asistencia en carretera (sí / no / sin indicar),
-- el teléfono de asistencia en carretera y el correo para comunicaciones con la aseguradora.
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
alter table public.flota add column if not exists seguro_franquicia numeric(10, 2);
alter table public.flota add column if not exists seguro_asistencia boolean;
alter table public.flota add column if not exists seguro_asistencia_telefono text;
alter table public.flota add column if not exists seguro_email text;

notify pgrst, 'reload schema';

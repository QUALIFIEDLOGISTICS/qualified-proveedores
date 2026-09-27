-- ============================================================
-- QUALIFIED PROVEEDORES — Rutas (cobertura de transportistas): se añade el
-- tipo de vehículo de cada ruta (lona, frigorífico, cisterna...).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.transportista_rutas add column if not exists tipo_vehiculo text;

-- ============================================================
-- QUALIFIED PROVEEDORES — enlace de Google Maps en Direcciones.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

alter table public.direcciones add column if not exists google_maps_url text;

-- ============================================================
-- QUALIFIED PROVEEDORES — Flota: número de flota, número de
-- bastidor y propietario.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

alter table public.flota add column if not exists numero_flota text;
alter table public.flota add column if not exists numero_bastidor text;
alter table public.flota add column if not exists propietario text;

-- ============================================================
-- QUALIFIED PROVEEDORES — Rutas (transportista_rutas): se guarda cuándo se
-- editó una cobertura por última vez, para mostrarla en el listado (si
-- nunca se ha editado, se muestra la fecha en que se creó).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.transportista_rutas add column if not exists updated_at timestamptz not null default now();

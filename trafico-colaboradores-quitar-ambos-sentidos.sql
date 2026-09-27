-- ============================================================
-- QUALIFIED PROVEEDORES — Colaboradores: se quita "también cubre el
-- sentido contrario", que ya no se usa en el código.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.transportista_rutas drop column if exists ambos_sentidos;

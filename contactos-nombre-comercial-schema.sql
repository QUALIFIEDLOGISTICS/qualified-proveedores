-- ============================================================
-- QUALIFIED PROVEEDORES — añade Nombre comercial a Contactos
-- (distinto de la Razón social).
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

alter table public.contactos add column if not exists nombre_comercial text;

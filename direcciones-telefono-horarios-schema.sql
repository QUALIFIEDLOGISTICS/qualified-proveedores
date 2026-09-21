-- ============================================================
-- QUALIFIED PROVEEDORES — Teléfono y horarios en Direcciones.
-- (El campo "contacto de referencia" deja de usarse en la web;
-- su columna se queda en la tabla sin tocar, por si acaso.)
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

alter table public.direcciones add column if not exists telefono text;
alter table public.direcciones add column if not exists horarios text;

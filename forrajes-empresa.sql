-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: nombre de la empresa (opcional) en proveedores y clientes
-- Sirve para buscar sus facturas en la contabilidad con el nombre que sale en ellas (razón social).
-- Es seguro ejecutarlo más de una vez y no cambia nada de lo que ya hay.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
alter table public.forraje_proveedores add column if not exists empresa text;
alter table public.forraje_clientes add column if not exists empresa text;

notify pgrst, 'reload schema';

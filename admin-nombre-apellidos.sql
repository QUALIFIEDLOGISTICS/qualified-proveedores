-- ============================================================
-- QUALIFIED PROVEEDORES — Gestión de Permisos: nombre y apellidos de cada
-- usuario, para saber qué persona ha hecho cada cambio en los historiales
-- (chatter) aunque la cuenta use un correo genérico.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.profiles add column if not exists nombre text;
alter table public.profiles add column if not exists apellidos text;

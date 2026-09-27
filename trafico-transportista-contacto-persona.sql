-- ============================================================
-- QUALIFIED PROVEEDORES — Contacto de transporte: además del correo y el
-- teléfono, ahora se apunta el nombre, apellidos y cargo de la persona de
-- contacto. Se edita desde la pestaña Transporte de la ficha (Tráfico → Transportistas).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.contactos add column if not exists nombre_transportista text;
alter table public.contactos add column if not exists apellidos_transportista text;
alter table public.contactos add column if not exists cargo_transportista text;

-- ============================================================
-- QUALIFIED PROVEEDORES — a partir de ahora, un usuario nuevo (creado en
-- Supabase → Authentication → Users) empieza SIN ningún módulo marcado,
-- en vez de con Clientes/Franjas/Documentos/Tráfico/Autónomos por defecto.
-- Hay que entrar en Gestión de Permisos y dárselos a mano.
-- No toca a los usuarios que ya existen (ver nota abajo).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.profiles alter column allowed_tabs set default '[]'::jsonb;

-- Nota: esto solo cambia lo que se apunta en las cuentas NUEVAS a partir de
-- ahora. No toca las que ya existen (no hay forma segura de distinguir, en
-- una cuenta que ya tenga exactamente esos módulos, si nunca se le configuró
-- nada o si de verdad se decidió dársela así) — revísalas a mano en Gestión
-- de Permisos si crees que alguna se quedó con el valor de antes sin querer.

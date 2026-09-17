-- ============================================================
-- QUALIFIED PROVEEDORES — Unificación de Clientes y Empresas en
-- Contactos (paso 3 de 3, FINAL): borra las tablas antiguas.
--
-- Ejecutar SOLO después de haber confirmado en el panel real que
-- Clientes, Empresas y la asignación de conductores se ven y
-- funcionan exactamente igual que antes de la migración. Este paso
-- no se puede deshacer.
--
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez.
-- ============================================================

drop table public.client_warehouses;
drop table public.clients;
drop table public.companies;

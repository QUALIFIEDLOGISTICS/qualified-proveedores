-- ============================================================
-- QUALIFIED PROVEEDORES — Rutas (transportista_rutas): se añade una tarifa
-- base orientativa por ruta y si ese transportista, además, factura
-- indexación de gasoil aparte (la tarifa guardada es siempre la base, sin
-- indexación incluida — igual que en Tarifas de cliente y en las tarifas
-- de conductor).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.transportista_rutas add column if not exists tarifa_base numeric;
alter table public.transportista_rutas add column if not exists indexacion boolean not null default false;

-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes · Viajes: «¿se le ha pagado al proveedor?» y «¿se ha cobrado al cliente?»
-- Hasta ahora el viaje solo sabía si había factura (facturado_proveedor / facturado_cliente). Se añaden dos casillas más:
--   pagado_proveedor  → ya se ha pagado al proveedor
--   cobrado_cliente   → ya se ha cobrado al cliente
-- No cambia ningún viaje existente (todos empiezan en «no»). Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.forraje_viajes add column if not exists pagado_proveedor boolean not null default false;
alter table public.forraje_viajes add column if not exists cobrado_cliente  boolean not null default false;

notify pgrst, 'reload schema';

-- Comprobación: deben salir 2 filas
select column_name from information_schema.columns
where table_schema = 'public' and table_name = 'forraje_viajes' and column_name in ('pagado_proveedor', 'cobrado_cliente') order by 1;

-- =====================================================================
-- Órdenes de carga · referencia de facturación propia
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
--
--   ref_facturacion  La referencia que el transportista tiene que poner en su factura.
--                    Se escribe a mano al crear la orden; ya no es el número de orden (OC-0001).
-- =====================================================================

alter table public.ordenes_carga add column if not exists ref_facturacion text;

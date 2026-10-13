-- =====================================================================
-- Direcciones · observaciones para órdenes de carga
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
--
--   observaciones_oc  Lo que siempre tiene que saber el transportista en esta dirección.
--                     Al elegir la dirección en una orden de carga, se copia sola en las observaciones del punto.
--                     (El campo «observaciones» de siempre queda para notas generales de la dirección.)
-- =====================================================================

alter table public.direcciones add column if not exists observaciones_oc text;

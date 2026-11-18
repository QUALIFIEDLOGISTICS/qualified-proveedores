-- ============================================================
-- QUALIFIED PROVEEDORES — Órdenes de carga: poner «Lona» como vehículo a todas las que no lo tienen.
-- Solo rellena el campo tipo_vehiculo (nuevo) donde está vacío. No toca ninguna otra columna.
-- Hacerlo ANTES de la carga inicial de «Coberturas desde las OC» en Rutas, para que las coberturas salgan ya con su vehículo.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

update public.ordenes_carga set tipo_vehiculo = 'Lona' where tipo_vehiculo is null;

-- Comprobación: todas deben salir como Lona
select coalesce(tipo_vehiculo, '(vacío)') as vehiculo, count(*) as ordenes
from public.ordenes_carga group by 1 order by 2 desc;

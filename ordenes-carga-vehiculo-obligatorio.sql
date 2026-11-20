-- ============================================================
-- QUALIFIED PROVEEDORES — Órdenes de carga · el vehículo es obligatorio también en la base de datos
-- Hasta ahora solo lo pedía la pantalla: quien tenía abierta una versión antigua de la web (una pestaña que lleva horas o días abierta)
-- seguía pudiendo guardar órdenes sin vehículo. Con esta regla la base de datos lo rechaza sea cual sea la pantalla o la versión.
-- No cambia ninguna orden existente (si alguna estuviera sin vehículo, Supabase avisa y no aplica la regla: no se pierde nada).
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.ordenes_carga drop constraint if exists ordenes_carga_vehiculo_obligatorio;
alter table public.ordenes_carga
  add constraint ordenes_carga_vehiculo_obligatorio check (coalesce(btrim(tipo_vehiculo), '') <> '');

notify pgrst, 'reload schema';

-- Comprobación: debe salir 1 fila (la regla) y ninguna orden sin vehículo
select conname as regla, (select count(*) from public.ordenes_carga where coalesce(btrim(tipo_vehiculo), '') = '') as ordenes_sin_vehiculo
from pg_constraint where conname = 'ordenes_carga_vehiculo_obligatorio';

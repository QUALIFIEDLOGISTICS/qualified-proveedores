-- ============================================================
-- QUALIFIED PROVEEDORES — Almacén → Productos: «Se cobra al…» y «Familia de carga»
-- Para que el SGA sepa solo qué producto cobrar en cada entrada, salida o día de stock.
--   disparador: entrada | salida | descarga | carga | stock_dia | stock_mes | manual
--   familia:    palet | palet_especial | bobina | caja  (vacío si no aplica)
-- Rellena los productos que ya existen a partir de su nombre, subtipo y unidad.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.almacenaje_productos add column if not exists disparador text;
alter table public.almacenaje_productos add column if not exists familia text;

update public.almacenaje_productos set
  disparador = case
    when lower(nombre) like 'entrada%'   then 'entrada'
    when lower(nombre) like 'salida%'    then 'salida'
    when lower(nombre) like 'picking%'   then 'salida'
    when lower(nombre) like 'descarga%'  then 'descarga'
    when lower(nombre) like 'carga%'     then 'carga'
    when unidad = 'dia'                  then 'stock_dia'
    when unidad = 'mes'                  then 'stock_mes'
    else 'manual'
  end
where disparador is null;

update public.almacenaje_productos set
  familia = case
    when disparador in ('descarga', 'carga', 'manual', 'stock_mes') then null
    when lower(coalesce(subtipo_valor, '')) like '%especial%' then 'palet_especial'
    when lower(nombre) like 'bobina%' or lower(coalesce(subtipo_valor, '')) like '%bobina%' then 'bobina'
    when lower(coalesce(subtipo_valor, '')) like '%caja%' then 'caja'
    when lower(nombre) like 'palet%' or lower(coalesce(subtipo_valor, '')) like 'palet%' then 'palet'
    else null
  end
where familia is null;

notify pgrst, 'reload schema';

-- Para revisar cómo ha quedado:
-- select categoria, nombre, subtipo_valor, unidad, disparador, familia from public.almacenaje_productos order by categoria, nombre;

-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: rellenar las tarifas de cada proveedor y cliente a partir de sus viajes
-- Recorre los viajes de cada proveedor (precio de compra) y de cada cliente (precio de venta), por producto, formato de bala y unidad, en orden de fecha,
-- y apunta una línea de tarifa cada vez que el precio cambia, con la fecha del primer viaje a ese precio («saltos de fecha»).
--   · Si en un mismo día hay varios viajes con distinto precio, vale el del último.
--   · Se ignoran los viajes sin producto o con precio 0.
--   · No duplica: si ya hay una línea de esa persona, producto, formato, unidad y fecha, no la toca ni la repite.
--   · Las líneas creadas llevan «Histórico de viajes» como autor y «Calculada de los viajes» como nota, para reconocerlas y poder quitarlas (bloque 5).
-- Es seguro ejecutarlo más de una vez. Para los clientes hace falta haber ejecutado antes «forrajes-cliente-precios.sql».
-- Instrucciones: Supabase → SQL Editor → cada bloque por separado. Empieza por el 1 (solo lee).
-- ============================================================

-- BLOQUE 1 (solo lee): cuántas líneas se crearían
with base as (
  select proveedor_id as quien, producto_id, nullif(formato, '') as formato, unidad, fecha, precio_compra as precio,
         row_number() over (partition by proveedor_id, producto_id, coalesce(formato, ''), unidad, fecha order by numero desc nulls last, created_at desc) as rn
  from public.forraje_viajes where proveedor_id is not null and producto_id is not null and precio_compra > 0
), dia as (select * from base where rn = 1),
cambios as (select *, lag(precio) over (partition by quien, producto_id, coalesce(formato, ''), unidad order by fecha) as anterior from dia)
select 'proveedores' as de, count(distinct quien) as personas, count(*) as lineas_nuevas
from cambios c
where anterior is distinct from precio
  and not exists (select 1 from public.forraje_proveedor_precios x where x.proveedor_id = c.quien and x.producto_id = c.producto_id and coalesce(x.formato, '') = coalesce(c.formato, '') and x.unidad = c.unidad and x.fecha = c.fecha)
union all
select 'clientes', count(distinct quien), count(*) from (
  select cliente_id as quien, producto_id, nullif(formato, '') as formato, unidad, fecha, precio_venta as precio,
         lag(precio_venta) over (partition by cliente_id, producto_id, coalesce(formato, ''), unidad order by fecha) as anterior
  from (
    select *, row_number() over (partition by cliente_id, producto_id, coalesce(formato, ''), unidad, fecha order by numero desc nulls last, created_at desc) as rn
    from public.forraje_viajes where cliente_id is not null and producto_id is not null and precio_venta > 0
  ) b where rn = 1
) c where anterior is distinct from precio;

-- BLOQUE 2: proveedores (precio de compra)
insert into public.forraje_proveedor_precios (proveedor_id, producto_id, formato, precio, unidad, fecha, notas, created_by)
with base as (
  select proveedor_id as quien, producto_id, nullif(formato, '') as formato, unidad, fecha, precio_compra as precio,
         row_number() over (partition by proveedor_id, producto_id, coalesce(formato, ''), unidad, fecha order by numero desc nulls last, created_at desc) as rn
  from public.forraje_viajes where proveedor_id is not null and producto_id is not null and precio_compra > 0
), dia as (select * from base where rn = 1),
cambios as (select *, lag(precio) over (partition by quien, producto_id, coalesce(formato, ''), unidad order by fecha) as anterior from dia)
select c.quien, c.producto_id, c.formato, c.precio, c.unidad, c.fecha, 'Calculada de los viajes', 'Histórico de viajes'
from cambios c
where c.anterior is distinct from c.precio
  and not exists (select 1 from public.forraje_proveedor_precios x where x.proveedor_id = c.quien and x.producto_id = c.producto_id and coalesce(x.formato, '') = coalesce(c.formato, '') and x.unidad = c.unidad and x.fecha = c.fecha);

-- BLOQUE 3: clientes (precio de venta) — antes hay que haber ejecutado forrajes-cliente-precios.sql
insert into public.forraje_cliente_precios (cliente_id, producto_id, formato, precio, unidad, fecha, notas, created_by)
with base as (
  select cliente_id as quien, producto_id, nullif(formato, '') as formato, unidad, fecha, precio_venta as precio,
         row_number() over (partition by cliente_id, producto_id, coalesce(formato, ''), unidad, fecha order by numero desc nulls last, created_at desc) as rn
  from public.forraje_viajes where cliente_id is not null and producto_id is not null and precio_venta > 0
), dia as (select * from base where rn = 1),
cambios as (select *, lag(precio) over (partition by quien, producto_id, coalesce(formato, ''), unidad order by fecha) as anterior from dia)
select c.quien, c.producto_id, c.formato, c.precio, c.unidad, c.fecha, 'Calculada de los viajes', 'Histórico de viajes'
from cambios c
where c.anterior is distinct from c.precio
  and not exists (select 1 from public.forraje_cliente_precios x where x.cliente_id = c.quien and x.producto_id = c.producto_id and coalesce(x.formato, '') = coalesce(c.formato, '') and x.unidad = c.unidad and x.fecha = c.fecha);

-- BLOQUE 4 (solo lee): cuántas líneas tiene ahora cada proveedor y cada cliente de las calculadas
select 'proveedor' as de, p.nombre, count(*) as lineas, min(x.fecha) as desde, max(x.fecha) as hasta
from public.forraje_proveedor_precios x join public.forraje_proveedores p on p.id = x.proveedor_id
where x.created_by = 'Histórico de viajes' group by p.nombre
union all
select 'cliente', c.nombre, count(*), min(x.fecha), max(x.fecha)
from public.forraje_cliente_precios x join public.forraje_clientes c on c.id = x.cliente_id
where x.created_by = 'Histórico de viajes' group by c.nombre
order by 1, 3 desc;

-- BLOQUE 5 (deshacer, solo si quieres quitarlas): borra únicamente las líneas calculadas por este archivo; las que apuntaste tú a mano no se tocan
-- delete from public.forraje_proveedor_precios where created_by = 'Histórico de viajes';
-- delete from public.forraje_cliente_precios where created_by = 'Histórico de viajes';

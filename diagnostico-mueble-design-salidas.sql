-- SOLO LEE (no cambia nada). Mueble Design: ¿por qué una salida de cajas se cobra como salida de palet?
-- Ejecuta las 4 consultas y pega aquí los resultados.

-- 1) Qué tarifas tiene (aquí deben salir «Salida Palet» y «Salida Cajas»)
select p.nombre as producto, p.categoria, p.disparador, p.familia, t.precio, t.subtipo, t.fecha
from public.almacenaje_tarifas t
join public.contactos c on c.id = t.cliente_id
join public.almacenaje_productos p on p.id = t.tipo
where c.nombre ilike '%mueble%'
order by p.categoria, p.nombre, t.fecha desc;

-- 2) Tipos de carga que usa su mercancía y A QUÉ salida lleva cada uno (columna «cobra_salida_como»)
select p.nombre as tipo_de_carga, p.disparador, p.familia, s.nombre as cobra_salida_como,
       (select count(*) from public.sga_partidas x where x.producto_id = p.id and x.cliente_id = c.id and x.cantidad_actual > 0) as lineas_con_stock,
       (select coalesce(sum(x.cantidad_actual), 0) from public.sga_partidas x where x.producto_id = p.id and x.cliente_id = c.id and x.cantidad_actual > 0) as unidades_en_stock
from public.contactos c
join public.almacenaje_productos p on p.id in (
       select producto_id from public.sga_partidas where cliente_id = c.id
       union select producto_id from public.sga_articulos where cliente_id = c.id and producto_id is not null)
left join public.almacenaje_productos s on s.id = p.cobro_salida
where c.nombre ilike '%mueble%'
order by p.nombre;

-- 3) Artículos de su catálogo y el tipo de carga de cada uno
select a.nombre, a.referencia, p.nombre as tipo_de_carga, a.atributos->>'subtipo' as tipo_de_palet, a.archived
from public.sga_articulos a
join public.contactos c on c.id = a.cliente_id
left join public.almacenaje_productos p on p.id = a.producto_id
where c.nombre ilike '%mueble%'
order by a.nombre;

-- 4) Últimos cobros de salida (qué se ha cobrado de verdad)
select c2.fecha, p.nombre as producto_cobrado, c2.cantidad, c2.precio, c2.importe, c2.estado
from public.sga_cobros c2
join public.contactos c on c.id = c2.cliente_id
join public.almacenaje_productos p on p.id = c2.producto_id
where c.nombre ilike '%mueble%' and c2.origen = 'movimiento' and p.nombre ilike '%salida%'
order by c2.fecha desc, c2.created_at desc
limit 20;

-- ============================================================
-- QUALIFIED PROVEEDORES — DIAGNÓSTICO (solo lectura, no cambia nada)
-- Para entender por qué un cliente (p. ej. GLAS FACTORY) tiene «Tipo de carga» y «Tipo de palet» que dicen lo mismo.
-- Instrucciones: Supabase → SQL Editor → ejecuta UNA consulta cada vez (el editor solo enseña el resultado de la última que se ejecuta).
-- ============================================================

-- CONSULTA 1 · La tarifa de GLAS FACTORY: qué productos tiene y cómo está configurado cada uno
select coalesce(nullif(c.nombre_comercial, ''), c.nombre) as cliente,
       p.nombre as producto, p.disparador, p.categoria, p.familia,
       p.usa_subtipo, p.subtipo_valor, p.cobro_entrada, p.cobro_salida, p.archived,
       t.subtipo as subtipo_en_la_tarifa, t.precio, t.fecha
from public.almacenaje_tarifas t
join public.almacenaje_productos p on p.id = t.tipo
join public.contactos c on c.id = t.cliente_id
where c.nombre ilike '%glas%' or c.nombre_comercial ilike '%glas%'
order by p.disparador, p.nombre, t.fecha desc;

-- CONSULTA 2 · Lo que tiene guardado GLAS FACTORY en el stock: tipo de carga y tipo de palet de cada palet
select coalesce(nullif(c.nombre_comercial, ''), c.nombre) as cliente,
       pr.nombre as tipo_de_carga,
       pa.atributos ->> 'subtipo' as tipo_de_palet_en_el_palet,
       count(*) as partidas, sum(pa.cantidad_actual) as palets_en_almacen
from public.sga_partidas pa
join public.contactos c on c.id = pa.cliente_id
left join public.almacenaje_productos pr on pr.id = pa.producto_id
where pa.estado = 'activa' and pa.cantidad_actual > 0
  and (c.nombre ilike '%glas%' or c.nombre_comercial ilike '%glas%')
group by 1, 2, 3
order by 1, 2, 3;

-- CONSULTA 3 · TODOS los clientes: productos de su tarifa que se cobran al entrar o salir, para ver a cuáles les sale «Tipo de palet»
select cliente, string_agg(linea, '  ·  ' order by linea) as productos_de_movimiento
from (
  select distinct coalesce(nullif(c.nombre_comercial, ''), c.nombre) as cliente,
         p.nombre || ' [' || coalesce(p.disparador, '') || ']'
           || case when coalesce(p.subtipo_valor, '') <> '' then ' subtipo_fijo=' || p.subtipo_valor else '' end
           || case when coalesce(t.subtipo, '') <> '' then ' subtipo_en_tarifa=' || t.subtipo else '' end as linea
  from public.almacenaje_tarifas t
  join public.almacenaje_productos p on p.id = t.tipo
  join public.contactos c on c.id = t.cliente_id
  where p.disparador in ('entrada', 'salida', 'entrada_salida') and coalesce(p.archived, false) = false
) s
group by cliente
order by cliente;

-- CONSULTA 4 · TODOS los clientes: cuántos palets y artículos llevan ya anotado un «tipo de palet» (si es 0, quitarlo no pierde nada guardado)
select coalesce(nullif(c.nombre_comercial, ''), c.nombre) as cliente,
       (select count(*) from public.sga_partidas pa where pa.cliente_id = c.id and pa.atributos ? 'subtipo') as partidas_con_tipo_de_palet,
       (select count(*) from public.sga_articulos a where a.cliente_id = c.id and a.atributos ? 'subtipo') as articulos_con_tipo_de_palet
from public.contactos c
where exists (select 1 from public.sga_partidas pa where pa.cliente_id = c.id)
   or exists (select 1 from public.sga_articulos a where a.cliente_id = c.id)
order by 2 desc, 3 desc, 1;

-- CONSULTA 5 · GLASS FACTORY: a qué producto de entrada y de salida apunta cada tipo de carga (con los id), para comprobar que los enlaces son los correctos
select p.id, p.nombre, p.disparador, p.familia,
       p.cobro_entrada, e.nombre as cobro_entrada_es, p.cobro_salida, s.nombre as cobro_salida_es
from public.almacenaje_productos p
left join public.almacenaje_productos e on e.id = p.cobro_entrada
left join public.almacenaje_productos s on s.id = p.cobro_salida
where p.id in (select t.tipo from public.almacenaje_tarifas t join public.contactos c on c.id = t.cliente_id where c.nombre ilike '%glas%' or c.nombre_comercial ilike '%glas%')
order by p.disparador, p.nombre;

-- CONSULTA 6 · GLASS FACTORY: lo que se ha cobrado por movimientos (recepciones y expediciones), para ver si las salidas se han cobrado bien
select co.fecha, pr.nombre as producto, co.cantidad, co.precio, co.importe, co.estado
from public.sga_cobros co
join public.contactos c on c.id = co.cliente_id
left join public.almacenaje_productos pr on pr.id = co.producto_id
where (c.nombre ilike '%glas%' or c.nombre_comercial ilike '%glas%') and co.origen = 'movimiento'
order by co.fecha desc
limit 60;

-- CONSULTA 7 · Los 3 clientes que tienen «Tipo de palet» (ALMALIFT, GLASS FACTORY, KUKA ROBOTS): a qué producto de entrada y salida apunta cada tipo de carga
select coalesce(nullif(c.nombre_comercial, ''), c.nombre) as cliente, p.id, p.nombre, p.disparador, p.familia,
       p.cobro_entrada, e.nombre as cobro_entrada_es, p.cobro_salida, s.nombre as cobro_salida_es
from public.almacenaje_tarifas t
join public.contactos c on c.id = t.cliente_id
join public.almacenaje_productos p on p.id = t.tipo
left join public.almacenaje_productos e on e.id = p.cobro_entrada
left join public.almacenaje_productos s on s.id = p.cobro_salida
where c.nombre ~* 'glas|almalift|kuka' or c.nombre_comercial ~* 'glas|almalift|kuka'
group by 1, p.id, p.nombre, p.disparador, p.familia, p.cobro_entrada, e.nombre, p.cobro_salida, s.nombre
order by 1, p.disparador, p.nombre;

-- CONSULTA 8 · Los mismos 3 clientes: stock actual por tipo de carga y tipo de palet anotado
select coalesce(nullif(c.nombre_comercial, ''), c.nombre) as cliente,
       pr.nombre as tipo_de_carga, pa.atributos ->> 'subtipo' as tipo_de_palet_en_el_palet,
       count(*) as partidas, sum(pa.cantidad_actual) as palets_en_almacen
from public.sga_partidas pa
join public.contactos c on c.id = pa.cliente_id
left join public.almacenaje_productos pr on pr.id = pa.producto_id
where pa.estado = 'activa' and pa.cantidad_actual > 0
  and (c.nombre ~* 'glas|almalift|kuka' or c.nombre_comercial ~* 'glas|almalift|kuka')
group by 1, 2, 3
order by 1, 2, 3;

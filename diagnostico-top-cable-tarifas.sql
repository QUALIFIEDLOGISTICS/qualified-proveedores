-- SOLO LEE (no cambia nada). Top Cable: ¿por qué le salen en «Almacenaje» líneas de «Movimiento»?
-- Ejecuta las 2 consultas y pega aquí los resultados.

-- 1) Sus líneas de tarifa: dónde las pone la tarifa (columna guardada) y dónde dice el producto que van
select p.nombre as producto, t.subtipo, t.precio, t.fecha,
       t.tipo_actividad as guardada_en_la_tarifa,
       p.categoria      as categoria_del_producto,
       p.disparador,
       case when t.tipo_actividad <> p.categoria then 'NO COINCIDEN' else '' end as aviso
from public.almacenaje_tarifas t
join public.contactos c on c.id = t.cliente_id
left join public.almacenaje_productos p on p.id = t.tipo
where c.nombre ilike '%top cable%'
order by t.tipo_actividad, p.nombre, t.fecha desc;

-- 2) En toda la base: líneas cuya categoría guardada no coincide con la de su producto
select c.nombre as cliente, p.nombre as producto, t.tipo_actividad as guardada, p.categoria as del_producto, count(*) as lineas
from public.almacenaje_tarifas t
join public.contactos c on c.id = t.cliente_id
join public.almacenaje_productos p on p.id = t.tipo
where t.tipo_actividad <> p.categoria
group by 1, 2, 3, 4
order by 1, 2;

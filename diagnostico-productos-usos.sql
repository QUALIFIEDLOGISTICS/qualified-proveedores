-- SOLO LEE (no cambia nada). Dice, producto por producto, qué lo está usando.
-- Un producto solo se puede borrar si TODAS las columnas de "usos" valen 0.

-- 1) Todos los productos y cuántas cosas los usan
select
  p.nombre,
  p.categoria,
  p.disparador,
  p.archived as archivado,
  (select count(*) from public.almacenaje_tarifas t where t.tipo = p.id)                                   as tarifas,
  (select count(*) from public.sga_articulos a where a.producto_id = p.id)                                 as articulos,
  (select count(*) from public.sga_partidas x where x.producto_id = p.id)                                  as palets,
  (select count(*) from public.sga_cobros c where c.producto_id = p.id)                                    as cobros,
  (select count(*) from public.sga_servicios s where s.producto_id = p.id)                                 as servicios,
  (select count(*) from public.almacenaje_productos o where o.cobro_entrada = p.id or o.cobro_salida = p.id) as enlazado_desde_otros,
  p.id
from public.almacenaje_productos p
order by p.categoria, p.nombre;

-- 2) Tarifas actuales de GLASS FACTORY
select c.nombre as cliente, t.fecha, p.nombre as producto, p.id as producto_id, t.precio, t.subtipo, t.id as tarifa_id
from public.almacenaje_tarifas t
join public.contactos c on c.id = t.cliente_id
left join public.almacenaje_productos p on p.id = t.tipo
where c.nombre ilike '%glass%'
order by t.fecha desc, p.nombre;

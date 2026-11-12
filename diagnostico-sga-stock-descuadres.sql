-- ============================================================
-- QUALIFIED PROVEEDORES — Diagnóstico (solo LEE, no cambia nada): ¿el stock de cada partida cuadra con su libro de movimientos?
-- Cada partida tiene un stock actual y, aparte, un libro con todas sus entradas (+) y salidas (−). Si lo uno no es la suma de lo otro, algo no se descontó bien.
-- Instrucciones: Supabase → SQL Editor. Cambia  GLOBO  por una parte del nombre del cliente. Ejecuta cada bloque por separado.
-- ============================================================

-- BLOQUE 1: las partidas del cliente que están o han estado en Manresa (o que aún tienen stock), con su stock y su libro
select k.nombre as cliente, w.name as almacen, p.descripcion as articulo, p.referencia, p.estado,
       p.cantidad_inicial as recibidos, p.cantidad_actual as stock_actual,
       coalesce(s.suma, 0) as suma_del_libro, p.cantidad_actual - coalesce(s.suma, 0) as diferencia,
       coalesce(s.salidas, 0) as salidas_registradas
from public.sga_partidas p
join public.contactos k on k.id = p.cliente_id
left join public.warehouses w on w.id = p.warehouse_id
left join (select partida_id, sum(cantidad) as suma, coalesce(-sum(cantidad) filter (where tipo = 'salida'), 0) as salidas from public.sga_movimientos group by partida_id) s on s.partida_id = p.id
where (k.nombre ilike '%GLOBO%' or coalesce(k.nombre_comercial, '') ilike '%GLOBO%')
  and (w.name ilike '%manresa%' or p.cantidad_actual > 0)
order by w.name, p.descripcion;

-- BLOQUE 2: partidas de CUALQUIER cliente cuyo stock no cuadra con su libro (lo normal es que no salga ninguna)
select k.nombre as cliente, w.name as almacen, p.descripcion as articulo, p.estado, p.cantidad_actual as stock_actual, coalesce(s.suma, 0) as suma_del_libro,
       p.cantidad_actual - coalesce(s.suma, 0) as diferencia
from public.sga_partidas p
join public.contactos k on k.id = p.cliente_id
left join public.warehouses w on w.id = p.warehouse_id
left join (select partida_id, sum(cantidad) as suma from public.sga_movimientos group by partida_id) s on s.partida_id = p.id
where p.cantidad_actual <> coalesce(s.suma, 0)
order by k.nombre, p.descripcion
limit 100;

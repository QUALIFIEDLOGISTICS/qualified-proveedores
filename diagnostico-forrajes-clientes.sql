-- ============================================================
-- QUALIFIED PROVEEDORES — Diagnóstico (solo LEE, no cambia nada): clientes de Forrajes que son el mismo con distinto nombre de granja
-- Instrucciones: Supabase → SQL Editor. Cambia  PARTE_DEL_NOMBRE  por una parte del nombre del cliente. Ejecuta cada bloque por separado.
-- ============================================================

-- BLOQUE 1: los clientes que se llaman parecido, con cuántos viajes tiene cada uno y su zona/teléfono
select c.id, c.nombre, c.zona, c.telefono, c.forma_pago, c.archived, count(v.id) as viajes
from public.forraje_clientes c
left join public.forraje_viajes v on v.cliente_id = c.id
where c.nombre ilike '%PARTE_DEL_NOMBRE%'
group by c.id
order by c.nombre;

-- BLOQUE 2: qué lugar de descarga se ha escrito en esos viajes (para ver si el nombre de la granja ya está ahí o solo en el nombre del cliente)
select c.nombre as cliente, v.zona_descarga, count(*) as viajes, min(v.fecha) as primer_viaje, max(v.fecha) as ultimo_viaje
from public.forraje_viajes v
join public.forraje_clientes c on c.id = v.cliente_id
where c.nombre ilike '%PARTE_DEL_NOMBRE%'
group by c.nombre, v.zona_descarga
order by c.nombre, v.zona_descarga;

-- BLOQUE 3: ¿hay otros clientes con el mismo problema? Nombres que empiezan igual (los 20 primeros caracteres) y son más de uno
select left(upper(nombre), 20) as empieza_por, count(*) as clientes, string_agg(nombre, '  |  ' order by nombre) as nombres
from public.forraje_clientes
where not archived
group by left(upper(nombre), 20)
having count(*) > 1
order by 2 desc;

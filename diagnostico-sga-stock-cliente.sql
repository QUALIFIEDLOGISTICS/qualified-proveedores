-- ============================================================
-- QUALIFIED PROVEEDORES — Diagnóstico (solo LEE, no cambia nada): ¿cuánto stock tiene de verdad un cliente en la base de datos?
-- Sirve para comprobar si lo que enseña la pantalla (Inventario / Expediciones) coincide con lo guardado.
-- Instrucciones: Supabase → SQL Editor. Cambia  CLIENTE  por una parte del nombre del cliente (p. ej. AKAN) y pulsa Run.
-- Ejecuta cada bloque por separado (el editor solo enseña el resultado del último).
-- ============================================================

-- BLOQUE 1: cuántas partidas activas hay en TODO el almacén (la pantalla solo puede cargar 1000 de golpe) y cuántas son de este cliente
select count(*) as partidas_activas_en_total,
       count(*) filter (where cliente_id in (select id from public.contactos where nombre ilike '%CLIENTE%' or coalesce(nombre_comercial, '') ilike '%CLIENTE%')) as partidas_del_cliente,
       coalesce(sum(cantidad_actual) filter (where cliente_id in (select id from public.contactos where nombre ilike '%CLIENTE%' or coalesce(nombre_comercial, '') ilike '%CLIENTE%')), 0) as unidades_del_cliente
from public.sga_partidas where estado = 'activa' and cantidad_actual > 0;

-- BLOQUE 2: lo mismo desglosado por tipo de carga del cliente
select coalesce(pr.nombre, '(sin tipo de carga)') as tipo_de_carga, count(*) as partidas, sum(p.cantidad_actual) as unidades
from public.sga_partidas p
join public.contactos c on c.id = p.cliente_id
left join public.almacenaje_productos pr on pr.id = p.producto_id
where p.estado = 'activa' and p.cantidad_actual > 0 and (c.nombre ilike '%CLIENTE%' or coalesce(c.nombre_comercial, '') ilike '%CLIENTE%')
group by 1 order by 3 desc;

-- BLOQUE 3: los albaranes del cliente y los palets que mueve cada uno (entradas, salidas, stock inicial…)
select a.tipo, a.estado, count(distinct a.id) as albaranes, count(m.id) as movimientos, coalesce(sum(m.cantidad), 0) as suma_cantidades
from public.sga_albaranes a
join public.contactos c on c.id = a.cliente_id
left join public.sga_movimientos m on m.albaran_id = a.id
where c.nombre ilike '%CLIENTE%' or coalesce(c.nombre_comercial, '') ilike '%CLIENTE%'
group by 1, 2 order by 1, 2;

-- ============================================================
-- QUALIFIED PROVEEDORES — Diagnóstico (solo LEE, no cambia nada): ¿qué artículos tiene un cliente de verdad en la base de datos?
-- Sirve para saber si un artículo «borrado» sigue existiendo (por eso no deja volver a crearlo) o si no está y el problema es otro.
-- Instrucciones: Supabase → SQL Editor. Cambia  CLIENTE  por una parte del nombre del cliente (p. ej. GLOBO) y pulsa Run.
-- Ejecuta cada bloque por separado (el editor solo enseña el resultado del último).
-- ============================================================

-- BLOQUE 1: los artículos que existen ahora mismo en ese cliente
select c.nombre as cliente, a.nombre as codigo_articulo, a.referencia, a.archived as archivado, a.created_at as creado,
       (select count(*) from public.sga_partidas p where p.articulo_id = a.id) as partidas
from public.sga_articulos a
join public.contactos c on c.id = a.cliente_id
where c.nombre ilike '%CLIENTE%' or coalesce(c.nombre_comercial, '') ilike '%CLIENTE%'
order by a.nombre;

-- BLOQUE 2: las reglas de «no repetir» que tiene la base de datos sobre los artículos
select indexname, indexdef from pg_indexes where schemaname = 'public' and tablename = 'sga_articulos';

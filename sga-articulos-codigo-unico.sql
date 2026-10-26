-- ============================================================
-- QUALIFIED PROVEEDORES — Catálogo de artículos: lo único es el CÓDIGO DE ARTÍCULO; la descripción puede repetirse
-- Antes no se podían tener dos artículos con la misma descripción. Ahora vale con que el código sea distinto.
-- PASO 1 (comprobación): esta consulta debe salir VACÍA. Si sale alguna fila, hay dos artículos del mismo cliente con el mismo código:
--   select cliente_id, lower(nombre) as codigo, count(*) from public.sga_articulos group by 1, 2 having count(*) > 1;
-- PASO 2: ejecuta lo de abajo.
-- ============================================================
drop index if exists public.sga_articulos_unico;
create unique index if not exists sga_articulos_codigo_unico on public.sga_articulos (cliente_id, lower(nombre));
notify pgrst, 'reload schema';

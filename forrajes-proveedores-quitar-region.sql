-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: quitar la región del nombre de los proveedores
-- Quita del nombre cosas como «F-31», «F31», «F09» o «(F-15)» (la región ya está en cada viaje y en la ficha del proveedor).
--   «NOMBRE F-31» → «NOMBRE»      «NOMBRE (F-15)» → «NOMBRE»      «NOMBRE F09 APELLIDO» → «NOMBRE APELLIDO»
-- Solo toca proveedores cuyo nombre lleve esa región. Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
update public.forraje_proveedores
set nombre = btrim(regexp_replace(regexp_replace(nombre, '\s*\(?\mF-?[0-9]{2,3}\M\)?', '', 'gi'), '\s{2,}', ' ', 'g'))
where nombre ~* '\mF-?[0-9]{2,3}\M'
  and btrim(regexp_replace(regexp_replace(nombre, '\s*\(?\mF-?[0-9]{2,3}\M\)?', '', 'gi'), '\s{2,}', ' ', 'g')) <> '';

-- Comprobación: todos los proveedores (ninguno debe llevar ya la región en el nombre) y si hay alguno repetido
select nombre, count(*) over (partition by lower(nombre)) as repetidos
from public.forraje_proveedores
order by nombre;

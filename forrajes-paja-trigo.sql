-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: «Paja» pasa a ser «Paja de trigo» y toda la paja sin formato es Rectangular
--   1) Los viajes de «Paja» se pasan al producto «Paja de trigo».
--   2) Los viajes que aún no tienen formato (la paja) se ponen en Rectangular. Si ya tenían uno, se respeta.
--   3) «Paja» se archiva al quedarse sin viajes (se puede eliminar luego desde la app).
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

-- «Paja de trigo» ya existe; si no estuviera, se crea
insert into public.forraje_productos (nombre)
select 'Paja de trigo'
where not exists (select 1 from public.forraje_productos where lower(nombre) = 'paja de trigo');

-- 1) Viajes de «Paja» → «Paja de trigo»
update public.forraje_viajes v
set producto_id = n.id
from public.forraje_productos o, public.forraje_productos n
where lower(o.nombre) = 'paja' and lower(n.nombre) = 'paja de trigo'
  and v.producto_id = o.id and o.id <> n.id;

-- 2) Toda la paja sin formato → Rectangular
update public.forraje_viajes v
set formato = 'Rectangular'
from public.forraje_productos p
where p.id = v.producto_id
  and lower(p.nombre) in ('paja de trigo', 'paja de arroz', 'paja de cebada')
  and v.formato is null;

-- 3) Archivar «Paja» si ya no tiene viajes
update public.forraje_productos p
set archived = true
where lower(p.nombre) = 'paja'
  and not exists (select 1 from public.forraje_viajes v where v.producto_id = p.id);

-- Comprobación: viajes por producto y formato (siguen sumando 302)
select p.nombre as producto, coalesce(v.formato, '(sin formato)') as formato, count(*) as viajes
from public.forraje_viajes v
left join public.forraje_productos p on p.id = v.producto_id
group by 1, 2
order by 1, 2;

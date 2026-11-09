-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: «Fenc» y «Heno» son lo mismo → todo queda como «Heno»
--   1) Los viajes de «Fenc» se pasan al producto «Heno» (el formato de cada viaje se conserva).
--   2) «Fenc» se archiva al quedarse sin viajes (se puede eliminar luego desde la app).
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

-- «Heno» ya existe; si no estuviera, se crea
insert into public.forraje_productos (nombre)
select 'Heno'
where not exists (select 1 from public.forraje_productos where lower(nombre) = 'heno');

-- 1) Viajes de «Fenc» → «Heno»
update public.forraje_viajes v
set producto_id = n.id
from public.forraje_productos o, public.forraje_productos n
where lower(o.nombre) = 'fenc' and lower(n.nombre) = 'heno'
  and v.producto_id = o.id and o.id <> n.id;

-- 2) Archivar «Fenc» si ya no tiene viajes
update public.forraje_productos p
set archived = true
where lower(p.nombre) = 'fenc'
  and not exists (select 1 from public.forraje_viajes v where v.producto_id = p.id);

-- Comprobación: viajes por producto y formato (siguen sumando 302)
select p.nombre as producto, coalesce(v.formato, '(sin formato)') as formato, count(*) as viajes
from public.forraje_viajes v
left join public.forraje_productos p on p.id = v.producto_id
group by 1, 2
order by 1, 2;

-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: un producto por género y el formato en cada viaje
--   Alfalfa cuadrada / Alfalfa ensilada            → Alfalfa            (Rectangular / Ensilada)
--   Fenc cuadrado / + redondo / top / rectangular  → Fenc               (Rectangular)
--   FENC REDONDO                                   → Fenc               (Redonda)
--   Balas ensiladas / Balas ensiladas ray-grass    → Ray-grass          (Ensilada)
-- Los viajes se pasan al producto nuevo y se les pone el formato (si ya tenían uno, se respeta).
-- Los productos antiguos se archivan (se pueden eliminar luego desde la app, ya sin viajes).
-- Paja, Paja de arroz, Paja de cebada, Paja de trigo y Heno no se tocan.
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

-- 1) Los productos base (si no existen ya)
insert into public.forraje_productos (nombre)
select t.n from (values ('Alfalfa'), ('Fenc'), ('Ray-grass')) as t(n)
where not exists (select 1 from public.forraje_productos x where lower(x.nombre) = lower(t.n));

-- 2) Pasar los viajes al producto base y ponerles el formato
with m(viejo, nuevo, formato) as (values
  ('Alfalfa cuadrada',          'Alfalfa',   'Rectangular'),
  ('Alfalfa ensilada',          'Alfalfa',   'Ensilada'),
  ('Balas ensiladas',           'Ray-grass', 'Ensilada'),
  ('Balas ensiladas ray-grass', 'Ray-grass', 'Ensilada'),
  ('Fenc cuadrado',             'Fenc',      'Rectangular'),
  ('Fenc cuadrado + redondo',   'Fenc',      'Rectangular'),
  ('Fenc cuadrado top',         'Fenc',      'Rectangular'),
  ('Fenc rectangular',          'Fenc',      'Rectangular'),
  ('Fenc redondo',              'Fenc',      'Redonda')
)
update public.forraje_viajes v
set producto_id = n.id,
    formato = coalesce(v.formato, m.formato)
from m
join public.forraje_productos o on lower(o.nombre) = lower(m.viejo)
join public.forraje_productos n on lower(n.nombre) = lower(m.nuevo)
where v.producto_id = o.id and o.id <> n.id;

-- 3) Archivar los productos antiguos que se han quedado sin viajes
update public.forraje_productos p
set archived = true
where lower(p.nombre) in ('alfalfa cuadrada', 'alfalfa ensilada', 'balas ensiladas', 'balas ensiladas ray-grass',
                          'fenc cuadrado', 'fenc cuadrado + redondo', 'fenc cuadrado top', 'fenc rectangular', 'fenc redondo')
  and not exists (select 1 from public.forraje_viajes v where v.producto_id = p.id);

-- Comprobación: viajes por producto y formato (los 302 viajes deben seguir sumando)
select p.nombre as producto, coalesce(v.formato, '(sin formato)') as formato, count(*) as viajes
from public.forraje_viajes v
left join public.forraje_productos p on p.id = v.producto_id
group by 1, 2
order by 1, 2;

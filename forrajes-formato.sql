-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: formato de la bala en cada viaje (Redonda, Rectangular o Ensilada)
-- Se elige en el viaje, aparte del producto (paja, fenc, alfalfa…).
-- Los viajes que ya había: si el nombre de su producto lo dice («Fenc redondo», «Balas ensiladas»…), se les pone el formato.
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
alter table public.forraje_viajes add column if not exists formato text;

update public.forraje_viajes v
set formato = case
    when lower(p.nombre) like '%ensilad%' then 'Ensilada'
    when lower(p.nombre) like '%redond%' then 'Redonda'
    when lower(p.nombre) like '%cuadrad%' or lower(p.nombre) like '%rectang%' then 'Rectangular'
  end
from public.forraje_productos p
where p.id = v.producto_id and v.formato is null
  and (lower(p.nombre) like '%ensilad%' or lower(p.nombre) like '%redond%' or lower(p.nombre) like '%cuadrad%' or lower(p.nombre) like '%rectang%');

notify pgrst, 'reload schema';

-- Comprobación: cuántos viajes hay de cada formato
select coalesce(formato, '(sin formato)') as formato, count(*) as viajes from public.forraje_viajes group by 1 order by 2 desc;

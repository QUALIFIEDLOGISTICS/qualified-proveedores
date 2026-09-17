-- ============================================================
-- QUALIFIED PROVEEDORES — corrige el código del DeCA para que
-- empiece en 1000. Solo hace falta ejecutar esto si YA habías
-- ejecutado antes deca-codigo-schema.sql (el que generaba códigos
-- desde el 0001). Este script:
--   1) actualiza la función para que, en un año nuevo, arranque en 1000
--   2) renumera los DeCA de este año ya creados para que empiecen en
--      1000 también (por orden de creación)
--   3) deja el contador del año listo para que el siguiente DeCA
--      continúe justo después del último renumerado
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez.
-- ============================================================

create or replace function public.assign_deca_codigo()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  yr int := extract(year from now())::int;
  seq int;
begin
  insert into public.deca_codigo_counters(year, next_seq) values (yr, 1001)
  on conflict (year) do update set next_seq = public.deca_codigo_counters.next_seq + 1
  returning next_seq - 1 into seq;
  new.codigo := yr::text || '-' || lpad(seq::text, 4, '0');
  return new;
end;
$$;

do $$
declare
  r record;
  seq int := 999;
  yr int := extract(year from now())::int;
begin
  for r in (
    select id from public.deca_documents
    where extract(year from created_at)::int = yr
    order by created_at
  ) loop
    seq := seq + 1;
    update public.deca_documents set codigo = yr::text || '-' || lpad(seq::text, 4, '0') where id = r.id;
  end loop;

  insert into public.deca_codigo_counters(year, next_seq) values (yr, seq + 1)
  on conflict (year) do update set next_seq = seq + 1;
end $$;

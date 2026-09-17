-- ============================================================
-- QUALIFIED PROVEEDORES — código único correlativo por año para
-- cada DeCA (ej. 2026-0001, 2026-0002...). Se asigna solo una vez,
-- automáticamente al crear el documento, y no cambia aunque se
-- edite después.
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores
-- (incluido deca-schema.sql).
-- ============================================================

alter table public.deca_documents add column if not exists codigo text unique;

create table if not exists public.deca_codigo_counters (
  year int primary key,
  next_seq int not null default 1
);
alter table public.deca_codigo_counters enable row level security;

create or replace function public.assign_deca_codigo()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  yr int := extract(year from now())::int;
  seq int;
begin
  insert into public.deca_codigo_counters(year, next_seq) values (yr, 2)
  on conflict (year) do update set next_seq = public.deca_codigo_counters.next_seq + 1
  returning next_seq - 1 into seq;
  new.codigo := yr::text || '-' || lpad(seq::text, 4, '0');
  return new;
end;
$$;

drop trigger if exists deca_documents_set_codigo on public.deca_documents;
create trigger deca_documents_set_codigo
before insert on public.deca_documents
for each row
when (new.codigo is null)
execute function public.assign_deca_codigo();

-- Asigna código a los DeCA creados antes de este cambio (si los hay) y
-- deja el contador de cada año listo para que el siguiente código nuevo
-- continúe justo después del último asignado aquí.
do $$
declare
  r record;
  seq int;
begin
  for r in (
    select id, extract(year from created_at)::int as yr
    from public.deca_documents
    where codigo is null
    order by created_at
  ) loop
    insert into public.deca_codigo_counters(year, next_seq) values (r.yr, 2)
    on conflict (year) do update set next_seq = public.deca_codigo_counters.next_seq + 1
    returning next_seq - 1 into seq;
    update public.deca_documents set codigo = r.yr::text || '-' || lpad(seq::text, 4, '0') where id = r.id;
  end loop;
end $$;

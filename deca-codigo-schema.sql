-- ============================================================
-- QUALIFIED PROVEEDORES — código único correlativo por año para
-- cada DeCA (ej. 2026-1000, 2026-1001..., empieza en 1000). Se
-- asigna solo una vez, automáticamente al crear el documento, y no
-- cambia aunque se edite después.
-- Este script es seguro de ejecutar aunque ya hayas ejecutado antes
-- una versión anterior (usa IF NOT EXISTS / OR REPLACE en todo, y
-- al final renumera lo que ya exista para que también empiece en
-- 1000, en vez de dar error o duplicar nada).
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run.
-- ============================================================

alter table public.deca_documents add column if not exists codigo text unique;

create table if not exists public.deca_codigo_counters (
  year int primary key,
  next_seq int not null default 1000
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
  insert into public.deca_codigo_counters(year, next_seq) values (yr, 1001)
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

-- Renumera TODOS los DeCA de cada año (tengan ya código o no) para que
-- cada año empiece limpio en 1000, por orden de creación, y deja el
-- contador de cada año listo para que el siguiente DeCA continúe justo
-- después del último renumerado aquí.
do $$
declare
  r record;
  seq int;
  cur_year int;
begin
  cur_year := null;
  seq := 999;
  for r in (
    select id, extract(year from created_at)::int as yr
    from public.deca_documents
    order by extract(year from created_at), created_at
  ) loop
    if cur_year is distinct from r.yr then
      if cur_year is not null then
        insert into public.deca_codigo_counters(year, next_seq) values (cur_year, seq + 1)
        on conflict (year) do update set next_seq = seq + 1;
      end if;
      cur_year := r.yr;
      seq := 999;
    end if;
    seq := seq + 1;
    update public.deca_documents set codigo = cur_year::text || '-' || lpad(seq::text, 4, '0') where id = r.id;
  end loop;
  if cur_year is not null then
    insert into public.deca_codigo_counters(year, next_seq) values (cur_year, seq + 1)
    on conflict (year) do update set next_seq = seq + 1;
  end if;
end $$;

-- ============================================================
-- QUALIFIED PROVEEDORES — CMR (carta de porte internacional) de las expediciones del SGA
-- Cuando una expedición es internacional (el país del almacén de salida no es el del destinatario) se genera el CMR desde el propio
-- formulario de la expedición. Cada CMR queda ligado a su expedición, con su número CMR-AAAA-NNNN (la numeración vuelve a 1 cada año)
-- y con los datos tal y como salieron en ese momento (el PDF se vuelve a dibujar con ellos cuando se abre).
-- No toca nada de lo que ya existe. Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

-- Contador por año (solo lo usa la función que asigna el número: nadie lo toca a mano)
create table if not exists public.cmr_contador (
  anio integer primary key,
  n integer not null default 0
);
alter table public.cmr_contador enable row level security;

create table if not exists public.cmr_documentos (
  id uuid primary key default gen_random_uuid(),
  codigo text unique,
  albaran_id uuid references public.sga_albaranes(id) on delete cascade,
  campos jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by text,
  updated_at timestamptz
);
-- Una expedición, un CMR
create unique index if not exists cmr_documentos_albaran_uq on public.cmr_documentos (albaran_id) where albaran_id is not null;

-- El número se asigna solo al crearlo: CMR-2026-0001, CMR-2026-0002…
create or replace function public.cmr_asignar_codigo() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_anio integer := extract(year from now())::integer;
  v_n integer;
begin
  if new.codigo is null or new.codigo = '' then
    insert into public.cmr_contador (anio, n) values (v_anio, 1)
      on conflict (anio) do update set n = public.cmr_contador.n + 1
      returning n into v_n;
    new.codigo := 'CMR-' || v_anio || '-' || lpad(v_n::text, 4, '0');
  end if;
  return new;
end $$;

drop trigger if exists cmr_documentos_codigo on public.cmr_documentos;
create trigger cmr_documentos_codigo before insert on public.cmr_documentos
  for each row execute function public.cmr_asignar_codigo();

-- Permisos: ver, crear y editar con acceso a Control de stock (o Transporte para verlos); solo administración borra
alter table public.cmr_documentos enable row level security;
drop policy if exists cmr_documentos_select on public.cmr_documentos;
drop policy if exists cmr_documentos_insert on public.cmr_documentos;
drop policy if exists cmr_documentos_update on public.cmr_documentos;
drop policy if exists cmr_documentos_delete on public.cmr_documentos;
create policy cmr_documentos_select on public.cmr_documentos for select using (public.sga_permiso('stock', 'trafico'));
create policy cmr_documentos_insert on public.cmr_documentos for insert with check (public.sga_permiso('stock'));
create policy cmr_documentos_update on public.cmr_documentos for update using (public.sga_permiso('stock'));
create policy cmr_documentos_delete on public.cmr_documentos for delete using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin));

notify pgrst, 'reload schema';

-- Comprobación: deben salir 2 filas (las dos tablas)
select table_name from information_schema.tables where table_schema = 'public' and table_name in ('cmr_documentos', 'cmr_contador') order by 1;

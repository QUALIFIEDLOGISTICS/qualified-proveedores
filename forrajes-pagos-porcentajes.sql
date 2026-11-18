-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes · Pagos: el porcentaje de cada socio puede cambiar con el tiempo (con fecha, como las tarifas)
-- Cada línea dice «desde esta fecha, este socio tiene este %». El beneficio de cada mes se reparte con el % vigente ese mes:
-- si un socio cambia de 25 % a 30 % desde enero de 2027, el reparto anterior no cambia y lo nuevo usa el 30 %.
-- Los socios que ya existen se quedan con su porcentaje actual «desde el inicio» (fecha 2000-01-01), así que no cambia ninguna cifra.
-- Solo administradores y cuentas con Forrajes + el apartado «Pagos». Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
create table if not exists public.forraje_socio_porcentajes (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  socio_id uuid not null references public.forraje_socios(id) on delete cascade,
  desde date not null,
  porcentaje numeric(6,3) not null check (porcentaje >= 0 and porcentaje <= 100),
  unique (socio_id, desde)
);

alter table public.forraje_socio_porcentajes enable row level security;
drop policy if exists forraje_socio_porcentajes_admin on public.forraje_socio_porcentajes;
drop policy if exists forraje_socio_porcentajes_pagos on public.forraje_socio_porcentajes;
create policy forraje_socio_porcentajes_pagos on public.forraje_socio_porcentajes for all
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or (p.allowed_tabs ? 'forrajes' and p.allowed_tabs ? 'forrajes:pagos'))))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or (p.allowed_tabs ? 'forrajes' and p.allowed_tabs ? 'forrajes:pagos'))));

-- Cada socio ya existente: su porcentaje actual, desde el inicio
insert into public.forraje_socio_porcentajes (socio_id, desde, porcentaje)
select s.id, date '2000-01-01', s.porcentaje from public.forraje_socios s
where not exists (select 1 from public.forraje_socio_porcentajes x where x.socio_id = s.id);

notify pgrst, 'reload schema';

-- Comprobación: una línea por socio
select s.nombre, x.desde, x.porcentaje
from public.forraje_socios s left join public.forraje_socio_porcentajes x on x.socio_id = s.id
order by s.orden, x.desde;

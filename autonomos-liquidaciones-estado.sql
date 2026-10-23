-- Autónomos · estado de la liquidación de cada mes: pendiente → revisada → facturada → pagada.
-- Una fila por conductor y mes; si no hay fila, el mes está «pendiente». Solo administradores y cuentas con Autónomos.
-- Es seguro ejecutarlo más de una vez.

create table if not exists public.autonomos_liquidaciones (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  year integer not null,
  month integer not null check (month between 0 and 11),
  estado text not null default 'pendiente' check (estado in ('pendiente', 'revisada', 'facturada', 'pagada')),
  updated_at timestamptz not null default now(),
  updated_by text,
  unique (driver_id, year, month)
);

alter table public.autonomos_liquidaciones enable row level security;

create policy autonomos_liquidaciones_select on public.autonomos_liquidaciones for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['autonomos'])));
create policy autonomos_liquidaciones_insert on public.autonomos_liquidaciones for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['autonomos'])));
create policy autonomos_liquidaciones_update on public.autonomos_liquidaciones for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['autonomos'])));
create policy autonomos_liquidaciones_delete on public.autonomos_liquidaciones for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['autonomos'])));

-- ============================================================
-- QUALIFIED PROVEEDORES — Módulo Flota (dentro de Administración):
-- tractoras y remolques con matrícula, marca, modelo y vencimientos
-- (ITV, seguro y, en tractoras, tacógrafo), más su historial de cambios.
-- Los permisos van incluidos aquí mismo (los mismos que Direcciones:
-- administradores y quien tenga la pestaña Administración).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.flota (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  tipo text not null default 'tractora' check (tipo in ('tractora','remolque')),
  matricula text not null,
  marca text,
  modelo text,
  itv_vence date,
  seguro_vence date,
  tacografo_vence date,
  archived boolean not null default false
);
create unique index if not exists flota_matricula_unica on public.flota (upper(matricula));

alter table public.flota enable row level security;

drop policy if exists flota_select on public.flota;
drop policy if exists flota_insert on public.flota;
drop policy if exists flota_update on public.flota;
drop policy if exists flota_delete on public.flota;

create policy flota_select on public.flota for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);
create policy flota_insert on public.flota for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);
create policy flota_update on public.flota for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);
create policy flota_delete on public.flota for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);

create table if not exists public.flota_historial (
  id uuid primary key default gen_random_uuid(),
  vehiculo_id uuid not null references public.flota(id) on delete cascade,
  created_at timestamptz not null default now(),
  usuario text,
  resumen text not null
);
alter table public.flota_historial enable row level security;

drop policy if exists flota_historial_select on public.flota_historial;
drop policy if exists flota_historial_insert on public.flota_historial;

create policy flota_historial_select on public.flota_historial for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);
create policy flota_historial_insert on public.flota_historial for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);

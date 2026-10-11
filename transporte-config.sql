-- =====================================================================
-- Transporte · Configuración (datos generales de las órdenes de carga)
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
--
--   transporte_config   Valores editables desde Transporte → Configuración: el cargador contractual, la información de
--                       facturación y las condiciones generales que salen en el PDF de las órdenes de carga.
--   Lo lee quien tiene el módulo Transporte; solo la modifican los administradores.
-- =====================================================================

create table if not exists public.transporte_config (
  clave text primary key,
  valor jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by text
);

alter table public.transporte_config enable row level security;
drop policy if exists transporte_config_select on public.transporte_config;
drop policy if exists transporte_config_insert on public.transporte_config;
drop policy if exists transporte_config_update on public.transporte_config;
create policy transporte_config_select on public.transporte_config for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy transporte_config_insert on public.transporte_config for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
);
create policy transporte_config_update on public.transporte_config for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
);

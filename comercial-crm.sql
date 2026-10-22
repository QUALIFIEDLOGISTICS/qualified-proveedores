-- ============================================================
-- QUALIFIED PROVEEDORES — Comercial → CRM: cotizaciones, seguimientos y prospectos
-- (clientes de transporte y de almacén). Solo administradores y cuentas con la pestaña Comercial.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Ejecútalo UNA vez.
-- ============================================================

-- Empresas a las que se ha cotizado y que todavía no son clientes
create table if not exists public.crm_prospectos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  nombre text not null,
  origen text,
  notas text,
  estado text not null default 'activo' check (estado in ('activo', 'cliente', 'descartado')),
  contacto_id uuid references public.contactos(id)
);

-- Cada cotización (oportunidad de venta)
create table if not exists public.crm_oportunidades (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  updated_at timestamptz not null default now(),
  updated_by text,
  titulo text not null,
  servicio text not null default 'transporte' check (servicio in ('transporte', 'almacen', 'mixto', 'otro')),
  prospecto_id uuid references public.crm_prospectos(id),
  contacto_id uuid references public.contactos(id),
  persona text,
  email text,
  telefono text,
  importe numeric(12,2),
  periodicidad text not null default 'unico' check (periodicidad in ('unico', 'mensual', 'anual')),
  fase text not null default 'cotizada' check (fase in ('cotizada', 'seguimiento', 'negociacion', 'ganada', 'perdida')),
  fecha_cotizacion date not null default current_date,
  proxima_fecha date,
  proxima_accion text,
  ultimo_contacto date,
  motivo_perdida text,
  cerrada_at timestamptz,
  notas text,
  constraint crm_oportunidades_empresa check (prospecto_id is not null or contacto_id is not null)
);
create index if not exists crm_oportunidades_fase_idx on public.crm_oportunidades (fase);
create index if not exists crm_oportunidades_proxima_idx on public.crm_oportunidades (proxima_fecha);
create index if not exists crm_oportunidades_prospecto_idx on public.crm_oportunidades (prospecto_id);
create index if not exists crm_oportunidades_contacto_idx on public.crm_oportunidades (contacto_id);

-- Historial de cada cotización: llamadas, correos, notas y cambios de fase
create table if not exists public.crm_actividades (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  oportunidad_id uuid not null references public.crm_oportunidades(id) on delete cascade,
  tipo text not null default 'nota',
  texto text,
  fecha date not null default current_date
);
create index if not exists crm_actividades_opp_idx on public.crm_actividades (oportunidad_id, created_at desc);

-- Seguridad: solo administradores y cuentas con Comercial
alter table public.crm_prospectos enable row level security;
alter table public.crm_oportunidades enable row level security;
alter table public.crm_actividades enable row level security;

create policy crm_prospectos_select on public.crm_prospectos for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_prospectos_insert on public.crm_prospectos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_prospectos_update on public.crm_prospectos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_prospectos_delete on public.crm_prospectos for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));

create policy crm_oportunidades_select on public.crm_oportunidades for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_oportunidades_insert on public.crm_oportunidades for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_oportunidades_update on public.crm_oportunidades for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_oportunidades_delete on public.crm_oportunidades for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));

create policy crm_actividades_select on public.crm_actividades for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_actividades_insert on public.crm_actividades for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_actividades_update on public.crm_actividades for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_actividades_delete on public.crm_actividades for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));

notify pgrst, 'reload schema';

-- ============================================================
-- QUALIFIED PROVEEDORES — Transporte → Mapa: estaciones AS24 (convenio), parkings vigilados y
-- lavaderos de camión de toda Europa, con sus precios (con histórico) y sus notas.
-- Solo administradores y cuentas con la pestaña Transporte lo ven y lo editan (Row Level Security activado).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Ejecútalo UNA vez (las tablas ya creadas no se tocan,
-- pero las reglas de seguridad de más abajo darían error si ya existen).
-- ============================================================

create table if not exists public.transporte_puntos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  updated_at timestamptz not null default now(),
  updated_by text,
  tipo text not null check (tipo in ('as24', 'parking', 'lavadero')),
  nombre text not null,
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  direccion text,
  localidad text,
  pais text,
  telefono text,
  web text,
  horario text,
  plazas integer check (plazas is null or plazas >= 0),
  maps_url text,
  servicios jsonb not null default '[]'::jsonb,
  observaciones text
);
create index if not exists transporte_puntos_tipo_idx on public.transporte_puntos (tipo);
create index if not exists transporte_puntos_pais_idx on public.transporte_puntos (pais);

-- Precios de cada punto. Cada cambio de precio es una fila nueva (con su fecha), así queda el histórico.
create table if not exists public.transporte_puntos_precios (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  punto_id uuid not null references public.transporte_puntos(id) on delete cascade,
  concepto text not null,
  unidad text,
  importe numeric(10,2) not null check (importe >= 0),
  moneda text not null default 'EUR',
  vigente_desde date not null default current_date,
  nota text
);
create index if not exists transporte_puntos_precios_punto_idx on public.transporte_puntos_precios (punto_id, vigente_desde desc);

-- Notas de cada punto (quién anotó qué y cuándo)
create table if not exists public.transporte_puntos_notas (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  punto_id uuid not null references public.transporte_puntos(id) on delete cascade,
  texto text not null
);
create index if not exists transporte_puntos_notas_punto_idx on public.transporte_puntos_notas (punto_id, created_at desc);

-- Seguridad: solo administradores y cuentas con Transporte
alter table public.transporte_puntos enable row level security;
alter table public.transporte_puntos_precios enable row level security;
alter table public.transporte_puntos_notas enable row level security;

create policy transporte_puntos_select on public.transporte_puntos for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])));
create policy transporte_puntos_insert on public.transporte_puntos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])));
create policy transporte_puntos_update on public.transporte_puntos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])));
create policy transporte_puntos_delete on public.transporte_puntos for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])));

create policy transporte_puntos_precios_select on public.transporte_puntos_precios for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])));
create policy transporte_puntos_precios_insert on public.transporte_puntos_precios for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])));
create policy transporte_puntos_precios_update on public.transporte_puntos_precios for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])));
create policy transporte_puntos_precios_delete on public.transporte_puntos_precios for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])));

create policy transporte_puntos_notas_select on public.transporte_puntos_notas for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])));
create policy transporte_puntos_notas_insert on public.transporte_puntos_notas for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])));
create policy transporte_puntos_notas_update on public.transporte_puntos_notas for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])));
create policy transporte_puntos_notas_delete on public.transporte_puntos_notas for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])));

notify pgrst, 'reload schema';

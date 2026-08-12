-- ============================================================
-- QUALIFIED PROVEEDORES — esquema inicial
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez.
-- ============================================================

create extension if not exists pgcrypto;

-- ---------- ALMACENES ----------
create table public.warehouses (
  id text primary key,
  name text not null,
  subtitle text,
  location_hint text,
  location text,
  color text
);

insert into public.warehouses (id, name, subtitle, location_hint, location, color) values
  ('balsareny', 'Balsareny', 'Zonas y estanterías', 'Ej. Zona 3 · Estantería A2', 'Balsareny', '#2E6F95'),
  ('sant-fruitos', 'Sant Fruitós de Bages', 'Zonas', 'Ej. Zona 5', 'Sant Fruitós de Bages', '#C98A2E'),
  ('pirelli-manresa', 'Pirelli Manresa', 'Naves y zonas', 'Ej. Nave 2 · Zona B', 'Manresa', '#8A4A35');

-- ---------- CLIENTES ----------
create table public.clients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  archived boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.client_warehouses (
  client_id uuid not null references public.clients(id) on delete cascade,
  warehouse_id text not null references public.warehouses(id) on delete cascade,
  primary key (client_id, warehouse_id)
);

-- ---------- PALETS ----------
create table public.pallets (
  id uuid primary key default gen_random_uuid(),
  warehouse_id text not null references public.warehouses(id),
  client_id uuid not null references public.clients(id),
  reference text,
  description text not null,
  quantity numeric not null default 0,
  unit text default 'palets',
  location text,
  status text not null default 'en almacén',
  date_in date not null default current_date
);

-- ---------- MOVIMIENTOS ----------
create table public.movements (
  id uuid primary key default gen_random_uuid(),
  warehouse_id text not null references public.warehouses(id),
  pallet_id uuid references public.pallets(id),
  client_id uuid references public.clients(id),
  type text not null,
  quantity numeric not null,
  date date not null default current_date,
  ref text
);

-- ---------- CITAS ----------
create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  warehouse_id text not null references public.warehouses(id),
  client_id uuid not null references public.clients(id),
  date date not null,
  start_time text not null,
  duration_min integer not null default 60,
  status text not null default 'planificado',
  carrier text,
  plate text,
  trailer_plate text,
  cargo_ref text,
  type text not null default 'descarga',
  notes text
);

-- ---------- CAMIONES SIN HORA FIJA ----------
create table public.unscheduled_trucks (
  id uuid primary key default gen_random_uuid(),
  warehouse_id text not null references public.warehouses(id),
  client_id uuid not null references public.clients(id),
  date date not null,
  status text not null default 'planificado',
  carrier text,
  plate text,
  trailer_plate text,
  cargo_ref text,
  type text not null default 'descarga',
  notes text
);

-- ---------- ADJUNTOS (de citas y camiones sin hora) ----------
create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  parent_type text not null check (parent_type in ('appointment','unscheduled')),
  parent_id uuid not null,
  name text not null,
  storage_path text not null,
  size integer,
  created_at timestamptz not null default now()
);

-- ---------- HORARIOS DE ALMACÉN ----------
create table public.warehouse_schedules (
  warehouse_id text not null references public.warehouses(id),
  weekday text not null check (weekday in ('lun','mar','mie','jue','vie','sab','dom')),
  open boolean not null default true,
  ranges jsonb not null default '[]'::jsonb,
  primary key (warehouse_id, weekday)
);

insert into public.warehouse_schedules (warehouse_id, weekday, open, ranges) values
  ('balsareny','lun',true,'[{"start":"09:00","end":"13:00"},{"start":"15:00","end":"18:00"}]'),
  ('balsareny','mar',true,'[{"start":"09:00","end":"13:00"},{"start":"15:00","end":"18:00"}]'),
  ('balsareny','mie',true,'[{"start":"09:00","end":"13:00"},{"start":"15:00","end":"18:00"}]'),
  ('balsareny','jue',true,'[{"start":"09:00","end":"13:00"},{"start":"15:00","end":"18:00"}]'),
  ('balsareny','vie',true,'[{"start":"09:00","end":"13:00"},{"start":"15:00","end":"18:00"}]'),
  ('balsareny','sab',true,'[{"start":"09:00","end":"13:00"}]'),
  ('balsareny','dom',false,'[{"start":"09:00","end":"13:00"}]'),
  ('sant-fruitos','lun',true,'[{"start":"08:00","end":"18:00"}]'),
  ('sant-fruitos','mar',true,'[{"start":"08:00","end":"18:00"}]'),
  ('sant-fruitos','mie',true,'[{"start":"08:00","end":"18:00"}]'),
  ('sant-fruitos','jue',true,'[{"start":"08:00","end":"18:00"}]'),
  ('sant-fruitos','vie',true,'[{"start":"08:00","end":"18:00"}]'),
  ('sant-fruitos','sab',false,'[{"start":"08:00","end":"18:00"}]'),
  ('sant-fruitos','dom',false,'[{"start":"08:00","end":"18:00"}]'),
  ('pirelli-manresa','lun',true,'[{"start":"08:00","end":"16:00"}]'),
  ('pirelli-manresa','mar',true,'[{"start":"08:00","end":"16:00"}]'),
  ('pirelli-manresa','mie',true,'[{"start":"08:00","end":"16:00"}]'),
  ('pirelli-manresa','jue',true,'[{"start":"08:00","end":"16:00"}]'),
  ('pirelli-manresa','vie',true,'[{"start":"08:00","end":"16:00"}]'),
  ('pirelli-manresa','sab',true,'[{"start":"09:00","end":"13:00"}]'),
  ('pirelli-manresa','dom',false,'[{"start":"09:00","end":"13:00"}]');

-- ---------- AUTÓNOMOS: EMPRESAS Y CONDUCTORES ----------
create table public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null
);

create table public.drivers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  name text not null,
  dni text,
  fleet_number text,
  archived boolean not null default false
);

create table public.driver_rates (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  valid_from date not null,
  price_day numeric not null default 0,
  price_km_extra numeric not null default 0,
  price_hour_extra numeric not null default 0,
  max_km_day numeric not null default 0,
  max_hours_day numeric not null default 0,
  unique (driver_id, valid_from)
);

create table public.weekly_entries (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  year integer not null,
  week integer not null,
  days_worked numeric not null default 0,
  km numeric not null default 0,
  hours numeric not null default 0,
  unique (driver_id, year, week)
);

create table public.fuel_entries (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  date date not null,
  liters numeric not null,
  price_per_liter numeric not null
);

create table public.supplement_entries (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  date date not null,
  amount numeric not null,
  reason text
);

create table public.expense_entries (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  date date not null,
  kind text not null check (kind in ('peaje','otro')),
  amount numeric not null,
  reason text
);

create table public.indexation_entries (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  year integer not null,
  month integer not null check (month between 0 and 11),
  percent numeric not null,
  unique (driver_id, year, month)
);

create table public.daily_entries (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  date date not null,
  status text not null default 'abierta' check (status in ('abierta','cerrada')),
  time_in text,
  time_out text,
  km_start numeric,
  km_end numeric,
  km numeric,
  photo_in_path text,
  photo_out_path text
);

-- ============================================================
-- RLS: toda tabla exige sesión iniciada. Sin acceso anónimo.
-- Acceso completo para cualquier cuenta autenticada (sin roles
-- todavía — decisión del usuario 2026-08-11).
-- ============================================================
do $$
declare t text;
begin
  for t in select unnest(array[
    'warehouses','clients','client_warehouses','pallets','movements',
    'appointments','unscheduled_trucks','attachments','warehouse_schedules',
    'companies','drivers','driver_rates','weekly_entries','fuel_entries',
    'supplement_entries','expense_entries','indexation_entries','daily_entries'
  ]) loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for select using (auth.role() = ''authenticated'')', t||'_select', t);
    execute format('create policy %I on public.%I for insert with check (auth.role() = ''authenticated'')', t||'_insert', t);
    execute format('create policy %I on public.%I for update using (auth.role() = ''authenticated'')', t||'_update', t);
    execute format('create policy %I on public.%I for delete using (auth.role() = ''authenticated'')', t||'_delete', t);
  end loop;
end $$;

-- ============================================================
-- STORAGE: bucket privado para PDFs adjuntos y fotos de tacógrafo
-- ============================================================
insert into storage.buckets (id, name, public)
values ('qualified-docs', 'qualified-docs', false)
on conflict (id) do nothing;

create policy "qualified_docs_select" on storage.objects for select
  using (bucket_id = 'qualified-docs' and auth.role() = 'authenticated');
create policy "qualified_docs_insert" on storage.objects for insert
  with check (bucket_id = 'qualified-docs' and auth.role() = 'authenticated');
create policy "qualified_docs_update" on storage.objects for update
  using (bucket_id = 'qualified-docs' and auth.role() = 'authenticated');
create policy "qualified_docs_delete" on storage.objects for delete
  using (bucket_id = 'qualified-docs' and auth.role() = 'authenticated');

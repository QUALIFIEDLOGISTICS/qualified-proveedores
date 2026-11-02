-- ============================================================
-- QUALIFIED PROVEEDORES — Flota: reparaciones, kilómetros y neumáticos
--  · Reparaciones y mantenimiento de cada vehículo (sin costes).
--  · Lecturas de kilómetros de las tractoras (a mano ahora; más adelante, desde el GPS).
--  · Neumáticos como piezas propias (nuevos o recauchutados) y su historial de montajes:
--    en qué vehículo y posición estuvo cada uno, desde cuándo y con cuántos km.
-- Los ve y los gestiona quien tenga la pestaña Administración (igual que Flota).
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

-- Configuración de ejes de cada vehículo (cuántas ruedas tiene y dónde)
alter table public.flota add column if not exists ejes_config text;

-- 1) Lecturas de kilómetros
create table if not exists public.flota_km (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  vehiculo_id uuid not null references public.flota(id) on delete cascade,
  fecha date not null,
  km integer not null check (km >= 0),
  origen text not null default 'manual',   -- 'manual' ahora; 'gps' cuando se integre
  nota text
);
create index if not exists flota_km_vehiculo_idx on public.flota_km (vehiculo_id, fecha desc, km desc);

-- 2) Neumáticos (cada uno es una pieza con su historial)
create table if not exists public.flota_neumaticos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  codigo text,
  marca text,
  medida text,
  modelo text,
  dot text,
  recauchutes integer not null default 0 check (recauchutes >= 0),
  estado text not null default 'almacen' check (estado in ('almacen', 'montado', 'recauchutando', 'desechado')),
  notas text
);

-- 3) Montajes: en qué vehículo y posición está o ha estado cada neumático
create table if not exists public.flota_montajes (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  neumatico_id uuid not null references public.flota_neumaticos(id) on delete cascade,
  vehiculo_id uuid not null references public.flota(id) on delete cascade,
  posicion text not null,
  fecha_montaje date not null,
  km_montaje integer,
  fecha_desmontaje date,
  km_desmontaje integer,
  motivo text,
  notas text
);
create index if not exists flota_montajes_vehiculo_idx on public.flota_montajes (vehiculo_id, fecha_montaje desc);
create index if not exists flota_montajes_neumatico_idx on public.flota_montajes (neumatico_id, fecha_montaje desc);
-- una sola rueda montada a la vez en cada posición, y un neumático solo puede estar montado en un sitio
create unique index if not exists flota_montajes_posicion_abierta on public.flota_montajes (vehiculo_id, posicion) where fecha_desmontaje is null;
create unique index if not exists flota_montajes_neumatico_abierto on public.flota_montajes (neumatico_id) where fecha_desmontaje is null;

-- 4) Reparaciones y mantenimiento
create table if not exists public.flota_intervenciones (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  vehiculo_id uuid not null references public.flota(id) on delete cascade,
  fecha date not null,
  tipo text not null default 'reparacion' check (tipo in ('reparacion', 'revision', 'neumaticos', 'otro')),
  descripcion text not null,
  taller text,
  km integer
);
create index if not exists flota_intervenciones_vehiculo_idx on public.flota_intervenciones (vehiculo_id, fecha desc);

-- 5) Permisos: los mismos que Flota (administradores y pestaña Administración)
do $$
declare t text;
begin
  foreach t in array array['flota_km', 'flota_neumaticos', 'flota_montajes', 'flota_intervenciones'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_select', t);
    execute format('drop policy if exists %I on public.%I', t || '_insert', t);
    execute format('drop policy if exists %I on public.%I', t || '_update', t);
    execute format('drop policy if exists %I on public.%I', t || '_delete', t);
    execute format('create policy %I on public.%I for select using (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array[''administracion'']))) ', t || '_select', t);
    execute format('create policy %I on public.%I for insert with check (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array[''administracion''])))', t || '_insert', t);
    execute format('create policy %I on public.%I for update using (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array[''administracion''])))', t || '_update', t);
    execute format('create policy %I on public.%I for delete using (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array[''administracion''])))', t || '_delete', t);
  end loop;
end $$;

notify pgrst, 'reload schema';

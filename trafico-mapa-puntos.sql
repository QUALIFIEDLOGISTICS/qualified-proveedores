-- ============================================================
-- QUALIFIED PROVEEDORES — Transporte → Mapa: estaciones AS24 (convenio), parkings vigilados y
-- lavaderos de camión de toda Europa, con sus precios (con histórico) y sus notas.
-- Solo administradores y cuentas con la pestaña Transporte lo ven y lo editan.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
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

-- Permisos: administradores y cuentas con Transporte
do $$
declare t text; p text;
begin
  foreach t in array array['transporte_puntos', 'transporte_puntos_precios', 'transporte_puntos_notas'] loop
    execute format('alter table public.%I enable row level security', t);
    foreach p in array array['select', 'insert', 'update', 'delete'] loop
      execute format('drop policy if exists %I on public.%I', t || '_' || p, t);
    end loop;
    execute format($f$create policy %I on public.%I for select using (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])))$f$, t || '_select', t);
    execute format($f$create policy %I on public.%I for insert with check (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])))$f$, t || '_insert', t);
    execute format($f$create policy %I on public.%I for update using (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])))$f$, t || '_update', t);
    execute format($f$create policy %I on public.%I for delete using (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico'])))$f$, t || '_delete', t);
  end loop;
end $$;

notify pgrst, 'reload schema';

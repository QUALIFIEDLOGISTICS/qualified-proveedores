-- ============================================================
-- QUALIFIED PROVEEDORES — Módulo FORRAJES (negocio paralelo de compra y venta de paja y forrajes, sin stock)
-- Un viaje = un camión que carga en un proveedor y descarga en un cliente: se compra, se vende y queda el beneficio.
-- Tablas: proveedores, clientes, productos y viajes. Solo las ve quien tenga la pestaña «Forrajes» (o sea administrador).
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.forraje_proveedores (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  nombre text not null,
  telefono text,
  zona text,              -- p. ej. F-31 (Francia, Alto Garona) o E-25 (España, Lleida)
  forma_pago text,        -- Efectivo, Factura contado, Factura 15 días…
  notas text,
  archived boolean not null default false
);
create unique index if not exists forraje_proveedores_nombre_uq on public.forraje_proveedores (lower(nombre));

create table if not exists public.forraje_clientes (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  nombre text not null,
  telefono text,
  zona text,
  forma_pago text,
  notas text,
  archived boolean not null default false
);
create unique index if not exists forraje_clientes_nombre_uq on public.forraje_clientes (lower(nombre));

create table if not exists public.forraje_productos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  nombre text not null,
  archived boolean not null default false
);
create unique index if not exists forraje_productos_nombre_uq on public.forraje_productos (lower(nombre));

create table if not exists public.forraje_viajes (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  numero integer,
  fecha date not null,
  proveedor_id uuid references public.forraje_proveedores(id) on delete set null,
  cliente_id uuid references public.forraje_clientes(id) on delete set null,
  zona_carga text,
  zona_descarga text,
  camion_carga text,        -- conductor / camión que carga (Q-28, T-134…)
  camion_descarga text,     -- el que descarga (puede ser otro)
  producto_id uuid references public.forraje_productos(id) on delete set null,
  cantidad numeric(12,3) not null default 0,
  unidad text not null default 't' check (unidad in ('t', 'balas')),
  pago_proveedor text,
  facturado_proveedor boolean not null default false,
  factura_proveedor text,
  tel_carga text,
  pago_cliente text,
  facturado_cliente boolean not null default false,
  factura_cliente text,
  tel_descarga text,
  precio_compra numeric(12,4) not null default 0,   -- € por tonelada (o por bala)
  flete numeric(12,2) not null default 0,           -- € del transporte del viaje
  precio_venta numeric(12,4) not null default 0,    -- € por tonelada (o por bala)
  notas text
);
create index if not exists forraje_viajes_fecha_idx on public.forraje_viajes (fecha desc);
create index if not exists forraje_viajes_proveedor_idx on public.forraje_viajes (proveedor_id);
create index if not exists forraje_viajes_cliente_idx on public.forraje_viajes (cliente_id);

-- Seguridad: solo administradores y cuentas con la pestaña «forrajes»
do $$
declare t text;
begin
  foreach t in array array['forraje_proveedores', 'forraje_clientes', 'forraje_productos', 'forraje_viajes'] loop
    execute format('alter table public.%1$s enable row level security', t);
    execute format('drop policy if exists %1$s_select on public.%1$s', t);
    execute format('drop policy if exists %1$s_insert on public.%1$s', t);
    execute format('drop policy if exists %1$s_update on public.%1$s', t);
    execute format('drop policy if exists %1$s_delete on public.%1$s', t);
    execute format('create policy %1$s_select on public.%1$s for select using (public.sga_permiso(''forrajes''))', t);
    execute format('create policy %1$s_insert on public.%1$s for insert with check (public.sga_permiso(''forrajes''))', t);
    execute format('create policy %1$s_update on public.%1$s for update using (public.sga_permiso(''forrajes''))', t);
    execute format('create policy %1$s_delete on public.%1$s for delete using (public.sga_permiso(''forrajes''))', t);
  end loop;
end $$;

notify pgrst, 'reload schema';

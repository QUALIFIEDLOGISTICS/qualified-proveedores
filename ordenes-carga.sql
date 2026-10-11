-- =====================================================================
-- Transporte · Órdenes de carga (OC)
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
--
--   ordenes_carga   Las órdenes con las que se contrata a un transportista para un viaje.
--                   El número es un contador propio que empieza en 1 (se enseña como OC-0001), distinto del S0xxxxx del otro programa.
--                   Cada orden puede llevar varias cargas y varias descargas, y un DeCA enlazado.
--   Lo ve quien tiene el módulo Transporte (igual que el DeCA).
-- =====================================================================

create sequence if not exists public.oc_numero_seq start 1;
grant usage, select on sequence public.oc_numero_seq to authenticated;

create table if not exists public.ordenes_carga (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by text,
  numero integer not null unique default nextval('public.oc_numero_seq'),    -- OC-0001, OC-0002…
  estado text not null default 'emitida' check (estado in ('emitida', 'anulada')),
  anulado_motivo text,
  fecha_pedido date not null default current_date,
  cliente_id uuid references public.contactos(id),                           -- cliente al que se vende el transporte
  transportista_id uuid references public.contactos(id),                     -- proveedor que hace el viaje
  transportista_nombre text,
  transportista_nif text,
  transportista_direccion text,
  transportista_poblacion text,
  matricula_tractora text,
  matricula_remolque text,
  mercancia text,
  indicaciones text,
  observaciones_especiales text,
  precio numeric(12,2),                                                      -- lo que se paga al transportista, en EUR
  cargas jsonb not null default '[]'::jsonb,                                 -- [{empresa, poblacion, direccion, cp, pais, fecha, hora, observaciones, ref}]
  descargas jsonb not null default '[]'::jsonb,
  peso_kg text,                                                              -- solo para el DeCA
  deca_id uuid references public.deca_documents(id) on delete set null
);
create index if not exists ordenes_carga_fecha_idx on public.ordenes_carga (fecha_pedido desc);

alter table public.ordenes_carga enable row level security;
drop policy if exists ordenes_carga_select on public.ordenes_carga;
drop policy if exists ordenes_carga_insert on public.ordenes_carga;
drop policy if exists ordenes_carga_update on public.ordenes_carga;
create policy ordenes_carga_select on public.ordenes_carga for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy ordenes_carga_insert on public.ordenes_carga for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy ordenes_carga_update on public.ordenes_carga for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
-- Una orden emitida solo se anula (queda con su número y su motivo). Las anuladas se pueden eliminar: ver ordenes-carga-eliminar.sql.

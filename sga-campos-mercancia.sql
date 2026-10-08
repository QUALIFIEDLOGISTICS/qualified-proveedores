-- =====================================================================
-- Control Stock SGA · Datos de mercancía configurables
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
--
--   sga_campos                Catálogo de campos propios (Almacén → Configuración → Datos de mercancía):
--                             nombre, tipo (texto, número, fecha, lista, sí/no), unidad, dónde vive
--                             (del artículo o de la entrada) y si sale en el albarán / en la tabla de stock.
--   sga_articulos.atributos   Valores de los campos «del artículo» (los «de la entrada» ya se guardaban en
--                             sga_partidas.atributos).
--   sga_clientes.campos       (ya existía) Qué campos usa cada cliente: no / opcional / obligatorio.
--
-- Nada se borra: un campo se archiva y los datos ya guardados se conservan.
-- =====================================================================

create table if not exists public.sga_campos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  clave text not null,                                    -- identificador interno estable (no cambia al renombrar)
  nombre text not null,
  tipo text not null default 'texto' check (tipo in ('texto', 'numero', 'fecha', 'lista', 'si_no')),
  unidad text,                                            -- kg, m, ud… (solo para números)
  opciones jsonb not null default '[]'::jsonb,            -- opciones de una lista
  ambito text not null default 'entrada' check (ambito in ('articulo', 'entrada')),
  en_albaran boolean not null default false,
  en_stock boolean not null default true,
  orden integer not null default 0,
  archived boolean not null default false
);
create unique index if not exists sga_campos_clave on public.sga_campos (clave);
create unique index if not exists sga_campos_nombre on public.sga_campos (lower(nombre)) where not archived;

alter table public.sga_campos enable row level security;
drop policy if exists sga_campos_select on public.sga_campos;
drop policy if exists sga_campos_insert on public.sga_campos;
drop policy if exists sga_campos_update on public.sga_campos;
create policy sga_campos_select on public.sga_campos for select using (public.sga_permiso('stock', 'almacenconfig', 'clientes', 'citas'));
create policy sga_campos_insert on public.sga_campos for insert with check (public.sga_permiso('almacenconfig'));
create policy sga_campos_update on public.sga_campos for update using (public.sga_permiso('almacenconfig'));

alter table public.sga_articulos add column if not exists atributos jsonb not null default '{}'::jsonb;

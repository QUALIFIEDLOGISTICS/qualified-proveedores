-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Naves de un almacén
-- Guarda cada nave con la forma de almacenar en ella: a suelo, en estantería o ambas.
-- (Las zonas siguen como están; la nave solo marca qué tipos de zona se pueden crear dentro.)
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
create table if not exists public.sga_naves (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  warehouse_id text not null references public.warehouses(id),
  nombre text not null,
  almacenaje text not null default 'ambas' check (almacenaje in ('suelo', 'estanteria', 'ambas'))
);
create unique index if not exists sga_naves_unica on public.sga_naves (warehouse_id, lower(nombre));

alter table public.sga_naves enable row level security;
drop policy if exists sga_naves_select on public.sga_naves;
drop policy if exists sga_naves_insert on public.sga_naves;
drop policy if exists sga_naves_update on public.sga_naves;
drop policy if exists sga_naves_delete on public.sga_naves;
create policy sga_naves_select on public.sga_naves for select using (public.sga_permiso('stock', 'almacenconfig', 'citas'));
create policy sga_naves_insert on public.sga_naves for insert with check (public.sga_permiso('almacenconfig'));
create policy sga_naves_update on public.sga_naves for update using (public.sga_permiso('almacenconfig'));
create policy sga_naves_delete on public.sga_naves for delete using (public.sga_permiso('almacenconfig'));

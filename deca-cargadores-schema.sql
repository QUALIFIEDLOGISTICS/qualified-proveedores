-- ============================================================
-- QUALIFIED PROVEEDORES — Cargadores contractuales (DeCA)
-- Lista reutilizable de cargadores (nombre, NIF, domicilio) para
-- rellenar los DeCA más rápido con un desplegable con buscador,
-- en vez de escribir los datos cada vez.
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores
-- (incluido deca-schema.sql).
-- ============================================================

create table public.cargadores_contractuales (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  nombre text not null,
  nif text not null,
  domicilio text
);

alter table public.cargadores_contractuales enable row level security;

create policy cargadores_contractuales_select on public.cargadores_contractuales for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy cargadores_contractuales_insert on public.cargadores_contractuales for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy cargadores_contractuales_update on public.cargadores_contractuales for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy cargadores_contractuales_delete on public.cargadores_contractuales for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);

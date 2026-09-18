-- ============================================================
-- QUALIFIED PROVEEDORES — Módulo Direcciones (dentro de
-- Administración): agenda de lugares (naves, muelles, puntos de
-- carga y descarga) con su dirección completa, un contacto de
-- referencia opcional y observaciones.
-- Los permisos van incluidos aquí mismo (los mismos que Contactos:
-- administradores y quien tenga la pestaña Administración).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.direcciones (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  nombre text not null,
  calle1 text,
  calle2 text,
  codigo_postal text,
  ciudad text,
  provincia text,
  pais text,
  contacto_id uuid references public.contactos(id) on delete set null,
  observaciones text,
  archived boolean not null default false
);

alter table public.direcciones enable row level security;

drop policy if exists direcciones_select on public.direcciones;
drop policy if exists direcciones_insert on public.direcciones;
drop policy if exists direcciones_update on public.direcciones;
drop policy if exists direcciones_delete on public.direcciones;

create policy direcciones_select on public.direcciones for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);
create policy direcciones_insert on public.direcciones for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);
create policy direcciones_update on public.direcciones for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);
create policy direcciones_delete on public.direcciones for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);

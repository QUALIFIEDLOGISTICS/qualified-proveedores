-- ============================================================
-- QUALIFIED PROVEEDORES — Historial de cambios de cada dirección
-- (quién cambió qué y cuándo), como en Contactos.
-- Los permisos van incluidos aquí mismo (los de Direcciones:
-- administradores y quien tenga la pestaña Administración).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.direccion_historial (
  id uuid primary key default gen_random_uuid(),
  direccion_id uuid not null references public.direcciones(id) on delete cascade,
  created_at timestamptz not null default now(),
  usuario text,
  resumen text not null
);
alter table public.direccion_historial enable row level security;

drop policy if exists direccion_historial_select on public.direccion_historial;
drop policy if exists direccion_historial_insert on public.direccion_historial;

create policy direccion_historial_select on public.direccion_historial for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);
create policy direccion_historial_insert on public.direccion_historial for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);

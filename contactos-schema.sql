-- ============================================================
-- QUALIFIED PROVEEDORES — Contactos, dentro del módulo
-- Administración. Agenda general de contactos (razón social, NIF,
-- dirección completa) — independiente de los Cargadores
-- contractuales del DeCA, aunque comparte los mismos campos.
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run.
-- ============================================================

create table public.contactos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  nombre text not null,
  nif text,
  calle1 text,
  calle2 text,
  codigo_postal text,
  ciudad text,
  provincia text,
  pais text
);

alter table public.contactos enable row level security;

create policy contactos_select on public.contactos for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);
create policy contactos_insert on public.contactos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);
create policy contactos_update on public.contactos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);
create policy contactos_delete on public.contactos for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion']))
);

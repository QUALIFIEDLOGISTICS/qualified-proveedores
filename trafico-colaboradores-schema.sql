-- ============================================================
-- QUALIFIED PROVEEDORES — Tráfico → Colaboradores: qué transportista
-- cubre cada ruta (zona de origen → zona de destino), para saber a
-- quién contactar cuando sobra un viaje. Solo administradores y cuentas
-- con la pestaña Tráfico la ven y la editan.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.transportista_rutas (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  contacto_id uuid not null references public.contactos(id) on delete cascade,
  origen_zona text not null,
  destino_zona text not null,
  ambos_sentidos boolean not null default false,
  observaciones text
);
create index if not exists transportista_rutas_contacto_idx on public.transportista_rutas (contacto_id);
create index if not exists transportista_rutas_ruta_idx on public.transportista_rutas (origen_zona, destino_zona);
alter table public.transportista_rutas enable row level security;

drop policy if exists transportista_rutas_select on public.transportista_rutas;
drop policy if exists transportista_rutas_insert on public.transportista_rutas;
drop policy if exists transportista_rutas_update on public.transportista_rutas;
drop policy if exists transportista_rutas_delete on public.transportista_rutas;

create policy transportista_rutas_select on public.transportista_rutas for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy transportista_rutas_insert on public.transportista_rutas for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy transportista_rutas_update on public.transportista_rutas for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy transportista_rutas_delete on public.transportista_rutas for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);

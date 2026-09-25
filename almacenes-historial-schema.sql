-- ============================================================
-- QUALIFIED PROVEEDORES — Historial de cambios de cada almacén
-- (quién cambió qué y cuándo), como en Contactos y Direcciones.
-- Solo los administradores lo ven y lo escriben, igual que la
-- pantalla Almacén → Configuración.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.warehouse_historial (
  id uuid primary key default gen_random_uuid(),
  warehouse_id text not null references public.warehouses(id) on delete cascade,
  created_at timestamptz not null default now(),
  usuario text,
  resumen text not null
);
alter table public.warehouse_historial enable row level security;

drop policy if exists warehouse_historial_select on public.warehouse_historial;
drop policy if exists warehouse_historial_insert on public.warehouse_historial;

create policy warehouse_historial_select on public.warehouse_historial for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
);
create policy warehouse_historial_insert on public.warehouse_historial for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
);

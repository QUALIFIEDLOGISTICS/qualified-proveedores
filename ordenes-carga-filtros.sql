-- =====================================================================
-- Órdenes de carga · filtros guardados
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
--
--   oc_filtros   Los filtros que se guardan con nombre desde la lista de órdenes de carga («Francia sin facturar»…).
--                Los ve y los usa todo el que tiene el módulo Transporte.
-- =====================================================================

create table if not exists public.oc_filtros (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  nombre text not null,
  filtro jsonb not null default '{}'::jsonb
);

alter table public.oc_filtros enable row level security;
drop policy if exists oc_filtros_select on public.oc_filtros;
drop policy if exists oc_filtros_insert on public.oc_filtros;
drop policy if exists oc_filtros_delete on public.oc_filtros;
create policy oc_filtros_select on public.oc_filtros for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy oc_filtros_insert on public.oc_filtros for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy oc_filtros_delete on public.oc_filtros for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);

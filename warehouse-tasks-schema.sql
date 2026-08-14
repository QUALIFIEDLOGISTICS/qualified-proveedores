-- ============================================================
-- QUALIFIED PROVEEDORES — tareas/recordatorios del almacén por día
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

create table if not exists public.warehouse_tasks (
  id uuid primary key default gen_random_uuid(),
  warehouse_id text not null references public.warehouses(id),
  date date not null,
  text text not null,
  done boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.warehouse_tasks enable row level security;

-- Mismo grupo de permiso que clientes/citas/documentos (Almacenes).
drop policy if exists warehouse_tasks_select on public.warehouse_tasks;
create policy warehouse_tasks_select on public.warehouse_tasks for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['clientes','citas','documentos']))
);
drop policy if exists warehouse_tasks_insert on public.warehouse_tasks;
create policy warehouse_tasks_insert on public.warehouse_tasks for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['clientes','citas','documentos']))
);
drop policy if exists warehouse_tasks_update on public.warehouse_tasks;
create policy warehouse_tasks_update on public.warehouse_tasks for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['clientes','citas','documentos']))
);
drop policy if exists warehouse_tasks_delete on public.warehouse_tasks;
create policy warehouse_tasks_delete on public.warehouse_tasks for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['clientes','citas','documentos']))
);

-- ============================================================
-- QUALIFIED PROVEEDORES — incidencias del día (avería, km de más
-- por error, u otra anotación) que pueden excluirse del cálculo de
-- máximo diario/semanal y del km/horas extra que se paga.
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

create table public.daily_incidents (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  date date not null,
  type text not null check (type in ('averia','km_error','otro')),
  hours_excluded numeric not null default 0,
  km_excluded numeric not null default 0,
  note text,
  created_at timestamptz not null default now()
);

alter table public.daily_incidents enable row level security;

-- Lectura: igual que daily_entries (trafico/autonomos/fichajes ya
-- necesitan verlas para que las alertas del Dashboard Tráfico y el
-- cálculo de la semana tengan en cuenta lo excluido).
create policy daily_incidents_select on public.daily_incidents for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos','fichajes']))
);
-- Crear/editar/borrar: solo quien puede corregir fichajes de verdad
-- (permiso "autonomos", igual que corregir/borrar un fichaje) ya que
-- esto cambia lo que se paga.
create policy daily_incidents_insert on public.daily_incidents for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);
create policy daily_incidents_update on public.daily_incidents for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);
create policy daily_incidents_delete on public.daily_incidents for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);

-- ============================================================
-- QUALIFIED PROVEEDORES — chatter / anotaciones libres por conductor
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

-- A diferencia de daily_incidents, esto NO afecta a ningún cálculo —
-- es solo un registro de texto libre para dejar constancia de algo en
-- una fecha, sin más.
create table public.driver_notes (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  date date not null,
  note text not null,
  created_at timestamptz not null default now()
);

alter table public.driver_notes enable row level security;

create policy driver_notes_select on public.driver_notes for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos','fichajes']))
);
create policy driver_notes_insert on public.driver_notes for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);
create policy driver_notes_delete on public.driver_notes for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);

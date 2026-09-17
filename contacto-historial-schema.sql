-- ============================================================
-- QUALIFIED PROVEEDORES — historial de cambios de cada contacto
-- (quién cambió qué y cuándo), para mostrarlo en un panel al lado
-- de la ficha del contacto.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

create table public.contacto_historial (
  id uuid primary key default gen_random_uuid(),
  contacto_id uuid not null references public.contactos(id) on delete cascade,
  created_at timestamptz not null default now(),
  usuario text,
  resumen text not null
);
alter table public.contacto_historial enable row level security;

create policy contacto_historial_select on public.contacto_historial for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos','trafico','autonomos']))
);
create policy contacto_historial_insert on public.contacto_historial for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos','trafico','autonomos']))
);

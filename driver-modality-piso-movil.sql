-- ============================================================
-- QUALIFIED PROVEEDORES — modalidad "Piso Móvil" (facturación
-- mensual + comisión), aparte de la modalidad "Plaza" ya existente.
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

alter table public.drivers
  add column if not exists modality text not null default 'plaza' check (modality in ('plaza','piso_movil'));

-- Un conductor de Piso Móvil no ficha ni tiene tarifa por día/km/hora:
-- cada mes se apunta la facturación de sus viajes y se le añade un %
-- de comisión sobre esa facturación. Total a cobrar = facturación +
-- facturación×comisión/100 — el % se guarda en cada mes (no hace
-- falta un histórico aparte, ya es "por mes" de por sí).
create table public.monthly_billing_entries (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  year integer not null,
  month integer not null check (month between 0 and 11),
  billing_amount numeric not null default 0,
  commission_percent numeric not null default 0,
  unique (driver_id, year, month)
);

alter table public.monthly_billing_entries enable row level security;

create policy monthly_billing_entries_select on public.monthly_billing_entries for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
);
create policy monthly_billing_entries_insert on public.monthly_billing_entries for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);
create policy monthly_billing_entries_update on public.monthly_billing_entries for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);
create policy monthly_billing_entries_delete on public.monthly_billing_entries for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);

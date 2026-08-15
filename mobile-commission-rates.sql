-- ============================================================
-- QUALIFIED PROVEEDORES — comisión de Piso Móvil con vigencia
-- (igual que las tarifas de Plaza: "desde este día, X%"), en vez de
-- escribirla a mano en cada factura mensual.
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

create table public.mobile_commission_rates (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  valid_from date not null,
  commission_percent numeric not null default 0,
  unique (driver_id, valid_from)
);

alter table public.mobile_commission_rates enable row level security;

create policy mobile_commission_rates_select on public.mobile_commission_rates for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
);
create policy mobile_commission_rates_insert on public.mobile_commission_rates for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);
create policy mobile_commission_rates_update on public.mobile_commission_rates for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);
create policy mobile_commission_rates_delete on public.mobile_commission_rates for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);

-- Ya no hace falta escribir el % a mano en cada mes: se calcula solo
-- a partir del histórico de arriba.
alter table public.monthly_billing_entries drop column if exists commission_percent;

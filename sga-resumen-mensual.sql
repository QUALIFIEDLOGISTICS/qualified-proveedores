-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Resumen mensual: metros cuadrados del mes
-- Guarda, por cliente y mes, los m² contratados (los 250 o 300 m² × 6 €/m² de tu hoja de facturación).
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================
create table if not exists public.sga_m2 (
  cliente_id uuid not null references public.contactos(id),
  periodo text not null check (periodo ~ '^[0-9]{4}-[0-9]{2}$'),     -- 'AAAA-MM'
  m2 numeric(12,2) not null check (m2 >= 0),
  updated_at timestamptz not null default now(),
  primary key (cliente_id, periodo)
);
alter table public.sga_m2 enable row level security;
drop policy if exists sga_m2_select on public.sga_m2;
drop policy if exists sga_m2_insert on public.sga_m2;
drop policy if exists sga_m2_update on public.sga_m2;
create policy sga_m2_select on public.sga_m2 for select using (public.sga_permiso('stock'));
create policy sga_m2_insert on public.sga_m2 for insert with check (public.sga_permiso('stock'));
create policy sga_m2_update on public.sga_m2 for update using (public.sga_permiso('stock'));

notify pgrst, 'reload schema';

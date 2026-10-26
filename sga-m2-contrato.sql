-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · m² contratados por cliente, con su histórico
-- Cada cambio de m² es una fila nueva con la fecha desde la que vale (no se borran ni se editan: así queda el histórico).
-- Las liquidaciones usan, para cada mes, los m² escritos a mano en ese mes y, si no hay, los vigentes a fin de mes en esta tabla.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
create table if not exists public.sga_m2_contrato (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.contactos(id),
  m2 numeric(12,2) not null check (m2 >= 0),
  vigente_desde date not null default current_date,
  nota text,
  created_by text,
  created_at timestamptz not null default now()
);
create index if not exists sga_m2_contrato_cliente_idx on public.sga_m2_contrato (cliente_id, vigente_desde desc);
alter table public.sga_m2_contrato enable row level security;
drop policy if exists sga_m2_contrato_select on public.sga_m2_contrato;
drop policy if exists sga_m2_contrato_insert on public.sga_m2_contrato;
create policy sga_m2_contrato_select on public.sga_m2_contrato for select using (public.sga_permiso('stock', 'almacenconfig', 'clientes'));
create policy sga_m2_contrato_insert on public.sga_m2_contrato for insert with check (public.sga_permiso('stock', 'almacenconfig'));

notify pgrst, 'reload schema';

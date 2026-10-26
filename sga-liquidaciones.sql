-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Liquidaciones mensuales de almacén
-- Guarda, por cliente y mes, cómo va la liquidación: pendiente, revisada o facturada, con el nº de factura, una nota
-- y el importe que se facturó (para avisar si después cambia). La lista de clientes y los importes se calculan solos.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
create table if not exists public.sga_liquidaciones (
  cliente_id uuid not null references public.contactos(id),
  periodo text not null check (periodo ~ '^[0-9]{4}-[0-9]{2}$'),     -- 'AAAA-MM'
  estado text not null default 'pendiente' check (estado in ('pendiente', 'revisada', 'facturada')),
  factura text,
  nota text,
  importe numeric(12,2),                                             -- total que había cuando se marcó como facturada
  updated_by text,
  updated_at timestamptz not null default now(),
  primary key (cliente_id, periodo)
);
alter table public.sga_liquidaciones enable row level security;
drop policy if exists sga_liquidaciones_select on public.sga_liquidaciones;
drop policy if exists sga_liquidaciones_insert on public.sga_liquidaciones;
drop policy if exists sga_liquidaciones_update on public.sga_liquidaciones;
create policy sga_liquidaciones_select on public.sga_liquidaciones for select using (public.sga_permiso('stock'));
create policy sga_liquidaciones_insert on public.sga_liquidaciones for insert with check (public.sga_permiso('stock'));
create policy sga_liquidaciones_update on public.sga_liquidaciones for update using (public.sga_permiso('stock'));

notify pgrst, 'reload schema';

-- ============================================================
-- QUALIFIED PROVEEDORES — Almacén · Costes: contratos y gastos fijos de los almacenes (alquiler de una nave, extintores, desratización, una carretilla…)
-- Cada coste lleva su importe (sin IVA), cada cuánto se paga (mensual, trimestral, semestral o anual) y su vigencia: desde una fecha, hasta otra o indefinido.
-- «Almacén» vacío = coste general (de todos los almacenes). Solo lo ven y lo editan los administradores y las cuentas con la pestaña «Costes de almacén» (Gestión de Permisos).
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
create table if not exists public.almacen_costes (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  warehouse_id text references public.warehouses(id) on delete set null,
  concepto text not null,
  categoria text not null default 'otros',
  proveedor text,
  importe numeric(12,2) not null check (importe >= 0),
  periodicidad text not null check (periodicidad in ('mensual', 'trimestral', 'semestral', 'anual')),
  fecha_inicio date not null,
  fecha_fin date,                     -- vacío = indefinido
  notas text,
  check (fecha_fin is null or fecha_fin >= fecha_inicio)
);
create index if not exists almacen_costes_alm_idx on public.almacen_costes (warehouse_id, fecha_inicio desc);

alter table public.almacen_costes enable row level security;
drop policy if exists almacen_costes_acceso on public.almacen_costes;
create policy almacen_costes_acceso on public.almacen_costes for all
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ? 'almacencostes')))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ? 'almacencostes')));

notify pgrst, 'reload schema';

-- Comprobación: debe salir 0 (todavía no hay costes)
select count(*) as costes from public.almacen_costes;

-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: productos que vende cada proveedor y sus precios (con fecha, como las tarifas)
-- A modo informativo: no cambia los viajes. Para actualizar un precio se añade una línea nueva con su fecha
-- y la anterior se queda en el historial. El vigente es el de la fecha más reciente de cada producto y formato.
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
create table if not exists public.forraje_proveedor_precios (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  proveedor_id uuid not null references public.forraje_proveedores(id) on delete cascade,
  producto_id uuid not null references public.forraje_productos(id) on delete cascade,
  formato text,                                   -- Redonda, Rectangular, Ensilada (opcional)
  precio numeric(12,4) not null check (precio >= 0),
  unidad text not null default 't' check (unidad in ('t', 'balas')),   -- € por tonelada o por bala
  fecha date not null default current_date,       -- desde cuándo vale este precio
  notas text
);
create index if not exists forraje_proveedor_precios_prov_idx on public.forraje_proveedor_precios (proveedor_id, fecha desc);

-- Seguridad: solo administradores y cuentas con la pestaña «forrajes» (igual que el resto de Forrajes)
alter table public.forraje_proveedor_precios enable row level security;
drop policy if exists forraje_proveedor_precios_select on public.forraje_proveedor_precios;
drop policy if exists forraje_proveedor_precios_insert on public.forraje_proveedor_precios;
drop policy if exists forraje_proveedor_precios_update on public.forraje_proveedor_precios;
drop policy if exists forraje_proveedor_precios_delete on public.forraje_proveedor_precios;
create policy forraje_proveedor_precios_select on public.forraje_proveedor_precios for select using (public.sga_permiso('forrajes'));
create policy forraje_proveedor_precios_insert on public.forraje_proveedor_precios for insert with check (public.sga_permiso('forrajes'));
create policy forraje_proveedor_precios_update on public.forraje_proveedor_precios for update using (public.sga_permiso('forrajes'));
create policy forraje_proveedor_precios_delete on public.forraje_proveedor_precios for delete using (public.sga_permiso('forrajes'));

notify pgrst, 'reload schema';

-- Comprobación: debe salir 0 (todavía no hay precios)
select count(*) as precios from public.forraje_proveedor_precios;

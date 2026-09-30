-- ============================================================
-- QUALIFIED PROVEEDORES — Catálogo de "Productos" de la tarifa de
-- almacenaje (antes una lista fija en el código: Palet, M², Bobina,
-- Entrada, Salida, Hora operario, Hora carretilla). Se convierte en una
-- tabla configurable desde Almacén → Configuración → Productos, para
-- poder añadir extras nuevos sin tocar código.
-- Se guarda con el mismo id ('palet', 'm2'...) que ya usan las tarifas
-- existentes en almacenaje_tarifas.tipo, para no romper nada.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.almacenaje_productos (
  id text primary key,
  created_at timestamptz not null default now(),
  nombre text not null,
  categoria text not null,       -- 'almacenaje' | 'movimiento' | 'extra'
  unidad text not null,          -- 'dia' | 'mes' | 'movimiento' | 'hora'
  usa_subtipo boolean not null default false,
  subtipo_label text,
  archived boolean not null default false
);
alter table public.almacenaje_productos enable row level security;

drop policy if exists almacenaje_productos_select on public.almacenaje_productos;
drop policy if exists almacenaje_productos_insert on public.almacenaje_productos;
drop policy if exists almacenaje_productos_update on public.almacenaje_productos;
drop policy if exists almacenaje_productos_delete on public.almacenaje_productos;

-- Ver el catálogo: cualquiera que pueda dar de alta una tarifa de almacenaje
-- (necesita elegir un producto de la lista).
create policy almacenaje_productos_select on public.almacenaje_productos for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos','almacenconfig']))
);
-- Gestionar el catálogo (crear, editar, archivar): solo quien tenga el
-- permiso de Configuración de almacenes, igual que para dar de alta almacenes.
create policy almacenaje_productos_insert on public.almacenaje_productos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['almacenconfig']))
);
create policy almacenaje_productos_update on public.almacenaje_productos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['almacenconfig']))
);
create policy almacenaje_productos_delete on public.almacenaje_productos for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['almacenconfig']))
);

-- Se siembra con los 7 productos que ya existían fijos en el código, con
-- los mismos id que ya llevan guardados las tarifas existentes.
insert into public.almacenaje_productos (id, nombre, categoria, unidad, usa_subtipo, subtipo_label) values
  ('palet', 'Palet', 'almacenaje', 'dia', true, 'Tipo de palet'),
  ('m2', 'M² ocupado', 'almacenaje', 'mes', false, null),
  ('bobina', 'Bobina', 'almacenaje', 'dia', false, null),
  ('entrada', 'Entrada', 'movimiento', 'movimiento', false, null),
  ('salida', 'Salida', 'movimiento', 'movimiento', false, null),
  ('hora_operario', 'Hora operario', 'extra', 'hora', false, null),
  ('hora_carretilla', 'Hora carretilla', 'extra', 'hora', false, null)
on conflict (id) do nothing;

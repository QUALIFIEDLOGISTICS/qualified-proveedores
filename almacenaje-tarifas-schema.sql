-- ============================================================
-- QUALIFIED PROVEEDORES — Tarifa de almacenaje de cada cliente (SGA, fase 1):
-- cuánto se le cobra por tener mercancía guardada (palet, por tipo de
-- palet, m², bobina) y por los movimientos (entrada/salida). Un cliente
-- puede combinar varios tipos a la vez (p. ej. palets Europeos + m²).
-- No depende del almacén: es la tarifa pactada con ese cliente.
-- Se ve y se edita desde la pestaña Almacén de su ficha.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.almacenaje_tarifas (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  cliente_id uuid not null references public.contactos(id) on delete cascade,
  fecha date not null,
  tipo text not null, -- 'palet' | 'm2' | 'bobina' | 'entrada' | 'salida'
  subtipo text,       -- solo para 'palet': "Europeo", "Americano"...
  precio numeric not null,
  observaciones text,
  created_by text
);
create index if not exists almacenaje_tarifas_cliente_idx on public.almacenaje_tarifas (cliente_id);
alter table public.almacenaje_tarifas enable row level security;

drop policy if exists almacenaje_tarifas_select on public.almacenaje_tarifas;
drop policy if exists almacenaje_tarifas_insert on public.almacenaje_tarifas;
drop policy if exists almacenaje_tarifas_update on public.almacenaje_tarifas;
drop policy if exists almacenaje_tarifas_delete on public.almacenaje_tarifas;

-- Mismo criterio que ya usa contacto_warehouses (asignar almacenes a un
-- cliente): quien pueda ver/editar la pestaña Almacén de su ficha.
create policy almacenaje_tarifas_select on public.almacenaje_tarifas for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos']))
);
create policy almacenaje_tarifas_insert on public.almacenaje_tarifas for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos']))
);
create policy almacenaje_tarifas_update on public.almacenaje_tarifas for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos']))
);
create policy almacenaje_tarifas_delete on public.almacenaje_tarifas for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos']))
);

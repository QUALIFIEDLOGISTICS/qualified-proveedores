-- ============================================================
-- QUALIFIED PROVEEDORES — arregla que los compañeros de Citas/
-- Tráfico no vean clientes ni empresas al reservar franjas.
-- La tabla "contactos" seguía con el permiso antiguo (solo
-- Administración veía cualquier contacto); esto la sustituye por
-- el reparto por rol: un contacto marcado "cliente de almacén" es
-- visible para quien tenga clientes/citas/documentos, uno marcado
-- "autónomos" para quien tenga trafico/autonomos — sin necesidad
-- de tener la pestaña Administración, y sin exponer los contactos
-- puramente administrativos (sin ningún rol marcado) a nadie más.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

drop policy if exists contactos_select on public.contactos;
drop policy if exists contactos_insert on public.contactos;
drop policy if exists contactos_update on public.contactos;
drop policy if exists contactos_delete on public.contactos;

create policy contactos_select on public.contactos for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['administracion'])
  or (es_cliente_almacen and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['clientes','citas','documentos']))
  or (es_autonomos and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico','autonomos']))
);
create policy contactos_insert on public.contactos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['administracion'])
  or (es_cliente_almacen and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['clientes','citas','documentos']))
  or (es_autonomos and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico','autonomos']))
);
create policy contactos_update on public.contactos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['administracion'])
  or (es_cliente_almacen and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['clientes','citas','documentos']))
  or (es_autonomos and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico','autonomos']))
);
create policy contactos_delete on public.contactos for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['administracion'])
  or (es_cliente_almacen and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['clientes','citas','documentos']))
  or (es_autonomos and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico','autonomos']))
);

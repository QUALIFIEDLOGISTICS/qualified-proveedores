-- ============================================================
-- QUALIFIED PROVEEDORES — Unificación de Clientes y Empresas en
-- Contactos (paso 2 de 3): repunta las claves foráneas y actualiza
-- los permisos (RLS) de contactos/contacto_warehouses.
--
-- IMPORTANTE: ejecutar SOLO después de haber pegado el paso 1 y de
-- que la nueva versión de panel.html (loaders de Clientes/Empresas
-- apuntando a "contactos") esté ya publicada. Antes de este paso,
-- confirma en el panel que Clientes y Empresas se ven igual que
-- siempre.
--
-- Este paso SÍ es el punto de no retorno de la migración: a partir
-- de aquí, pallets/movimientos/citas/camiones sin hora/conductores
-- ya no validan contra las tablas antiguas clients/companies.
--
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez.
-- ============================================================

alter table public.pallets drop constraint if exists pallets_client_id_fkey;
alter table public.pallets add constraint pallets_client_id_fkey
  foreign key (client_id) references public.contactos(id);

alter table public.movements drop constraint if exists movements_client_id_fkey;
alter table public.movements add constraint movements_client_id_fkey
  foreign key (client_id) references public.contactos(id);

alter table public.appointments drop constraint if exists appointments_client_id_fkey;
alter table public.appointments add constraint appointments_client_id_fkey
  foreign key (client_id) references public.contactos(id);

alter table public.unscheduled_trucks drop constraint if exists unscheduled_trucks_client_id_fkey;
alter table public.unscheduled_trucks add constraint unscheduled_trucks_client_id_fkey
  foreign key (client_id) references public.contactos(id);

alter table public.drivers drop constraint if exists drivers_company_id_fkey;
alter table public.drivers add constraint drivers_company_id_fkey
  foreign key (company_id) references public.contactos(id);

-- ---------- RLS de contactos: por pestaña Y por rol de la fila ----------
-- Un contacto marcado "cliente de almacén" es visible para quien tenga
-- clientes/citas/documentos (el mismo grupo que ya usaban clients/
-- client_warehouses); uno marcado "autónomos" para quien tenga
-- trafico/autonomos (igual que companies); Administración ve todo.
-- Así un contacto puramente administrativo (sin ningún rol marcado) NO
-- se hace visible para nadie fuera de Administración solo por unir esta
-- tabla — se comprueba el rol, no solo la pestaña.
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

drop policy if exists contacto_warehouses_select on public.contacto_warehouses;
drop policy if exists contacto_warehouses_insert on public.contacto_warehouses;
drop policy if exists contacto_warehouses_update on public.contacto_warehouses;
drop policy if exists contacto_warehouses_delete on public.contacto_warehouses;

create policy contacto_warehouses_select on public.contacto_warehouses for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos']))
);
create policy contacto_warehouses_insert on public.contacto_warehouses for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos']))
);
create policy contacto_warehouses_update on public.contacto_warehouses for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos']))
);
create policy contacto_warehouses_delete on public.contacto_warehouses for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos']))
);

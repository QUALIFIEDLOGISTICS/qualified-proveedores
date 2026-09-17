-- ============================================================
-- QUALIFIED PROVEEDORES — arregla la asignación de almacenes a un
-- contacto, que no se guardaba: la tabla contacto_warehouses se
-- creó con los permisos (RLS) activados pero sin ninguna política
-- todavía (esas venían en el paso 2 de la migración, que exige
-- confirmar antes que Clientes/Empresas se vean bien). Sin
-- políticas, Supabase bloqueaba en silencio cualquier guardado.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

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

-- ============================================================
-- QUALIFIED PROVEEDORES — "Configuración de almacenes" pasa a ser un permiso
-- que se puede dar desde Gestión de Permisos (antes solo lo tenían los
-- administradores). Se actualizan las políticas para que también puedan
-- crear, editar y archivar almacenes, y su horario, las cuentas con ese
-- permiso concreto — no hace falta ser administrador.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

drop policy if exists warehouses_insert on public.warehouses;
drop policy if exists warehouses_update on public.warehouses;
drop policy if exists warehouses_delete on public.warehouses;

create policy warehouses_insert on public.warehouses for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['almacenconfig']))
);
create policy warehouses_update on public.warehouses for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['almacenconfig']))
);
create policy warehouses_delete on public.warehouses for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['almacenconfig']))
);

drop policy if exists warehouse_schedules_insert on public.warehouse_schedules;
create policy warehouse_schedules_insert on public.warehouse_schedules for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['almacenconfig']))
);
drop policy if exists warehouse_schedules_update on public.warehouse_schedules;
create policy warehouse_schedules_update on public.warehouse_schedules for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['almacenconfig']))
);
drop policy if exists warehouse_schedules_delete on public.warehouse_schedules;
create policy warehouse_schedules_delete on public.warehouse_schedules for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['almacenconfig']))
);

drop policy if exists warehouse_historial_select on public.warehouse_historial;
drop policy if exists warehouse_historial_insert on public.warehouse_historial;
create policy warehouse_historial_select on public.warehouse_historial for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['almacenconfig']))
);
create policy warehouse_historial_insert on public.warehouse_historial for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['almacenconfig']))
);

-- ============================================================
-- QUALIFIED PROVEEDORES — permiso separado para el horario del
-- almacén (para el rol "Organizador", que no es administrador
-- pero sí gestiona el día a día del almacén).
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

alter table public.profiles add column can_edit_schedule boolean not null default false;

drop policy if exists warehouse_schedules_insert on public.warehouse_schedules;
create policy warehouse_schedules_insert on public.warehouse_schedules for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.can_edit_schedule))
);

drop policy if exists warehouse_schedules_update on public.warehouse_schedules;
create policy warehouse_schedules_update on public.warehouse_schedules for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.can_edit_schedule))
);

drop policy if exists warehouse_schedules_delete on public.warehouse_schedules;
create policy warehouse_schedules_delete on public.warehouse_schedules for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.can_edit_schedule))
);

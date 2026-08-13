-- ============================================================
-- QUALIFIED PROVEEDORES — el horario del almacén solo lo edita
-- un administrador (los trabajadores con acceso a "Citas" pueden
-- seguir viéndolo para reservar, pero no cambiarlo).
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

-- La lectura se queda igual (cualquiera con acceso a Almacenes puede
-- ver el horario, lo necesita para saber cuándo puede reservar).

drop policy if exists warehouse_schedules_insert on public.warehouse_schedules;
create policy warehouse_schedules_insert on public.warehouse_schedules for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
);

drop policy if exists warehouse_schedules_update on public.warehouse_schedules;
create policy warehouse_schedules_update on public.warehouse_schedules for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
);

drop policy if exists warehouse_schedules_delete on public.warehouse_schedules;
create policy warehouse_schedules_delete on public.warehouse_schedules for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
);

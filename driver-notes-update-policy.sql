-- ============================================================
-- QUALIFIED PROVEEDORES — permite editar una anotación ya creada
-- (driver_notes solo tenía permiso de insertar y borrar, no de
-- actualizar).
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

drop policy if exists driver_notes_update on public.driver_notes;
create policy driver_notes_update on public.driver_notes for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);

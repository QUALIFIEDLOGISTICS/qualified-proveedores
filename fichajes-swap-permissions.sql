-- ============================================================
-- QUALIFIED PROVEEDORES — invertir quién corrige/borra fichajes
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

-- Antes: corregir/borrar un fichaje exigía la pestaña "fichajes".
-- Ahora, a petición explícita: la pestaña "fichajes" solo sirve para
-- AÑADIR fichajes (fichar/registro manual), y corregir o borrar uno
-- ya existente pasa a exigir la pestaña "autonomos" (para no dar esa
-- capacidad a cuentas de fichaje puro). El acceso propio de un
-- conductor vinculado (driver_id = linked_driver_id(), usado por la
-- pantalla de fichaje para cerrar su propia jornada) no cambia.
drop policy if exists daily_entries_update on public.daily_entries;
create policy daily_entries_update on public.daily_entries for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
  or driver_id = public.linked_driver_id()
);
drop policy if exists daily_entries_delete on public.daily_entries;
create policy daily_entries_delete on public.daily_entries for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['autonomos']))
);

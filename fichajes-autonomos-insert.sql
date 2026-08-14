-- ============================================================
-- QUALIFIED PROVEEDORES — permitir añadir fichajes manuales también
-- desde el Panel de Control Autónomos, no solo desde Fichajes.
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

-- fichajes-schema.sql dejó daily_entries_insert exigiendo solo la
-- pestaña "fichajes" (a propósito, para separar dinero de fichar).
-- Ahora se añade "autonomos" también como pestaña válida para
-- INSERTAR (no para editar/borrar, eso sigue siendo solo de "fichajes")
-- porque el botón "+ Añadir fichaje manual" ya aparece también dentro
-- del Panel de Control Autónomos y, sin este cambio, una cuenta con
-- solo el permiso "autonomos" (sin "fichajes") vería el botón pero le
-- fallaría el guardado por RLS.
drop policy if exists daily_entries_insert on public.daily_entries;
create policy daily_entries_insert on public.daily_entries for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['fichajes','autonomos']))
  or driver_id = public.linked_driver_id()
);

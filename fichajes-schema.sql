-- ============================================================
-- QUALIFIED PROVEEDORES — módulo Fichajes independiente
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

-- ---------- DAILY_ENTRIES ----------
-- La LECTURA se queda abierta a trafico/autonomos/fichajes (Dashboard
-- Tráfico necesita leer los fichajes de hoy para calcular el estado de
-- cada conductor, aunque quien lo mira no tenga acceso a "Fichajes").
-- Crear/editar/borrar (la parte que el usuario quería separar de verdad)
-- pasa a exigir solo la pestaña "fichajes". El acceso propio de un
-- conductor vinculado (driver_id = linked_driver_id()) no cambia.
drop policy if exists daily_entries_select on public.daily_entries;
create policy daily_entries_select on public.daily_entries for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos','fichajes']))
  or driver_id = public.linked_driver_id()
);
drop policy if exists daily_entries_insert on public.daily_entries;
create policy daily_entries_insert on public.daily_entries for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['fichajes']))
  or driver_id = public.linked_driver_id()
);
drop policy if exists daily_entries_update on public.daily_entries;
create policy daily_entries_update on public.daily_entries for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['fichajes']))
  or driver_id = public.linked_driver_id()
);
drop policy if exists daily_entries_delete on public.daily_entries;
create policy daily_entries_delete on public.daily_entries for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['fichajes']))
);

-- ---------- WEEKLY_ENTRIES: "fichajes" se añade como pestaña válida ----------
-- (además de trafico/autonomos) porque corregir un fichaje dispara
-- recalcWeeksFromFichajes(), que necesita poder escribir aquí.
drop policy if exists weekly_entries_select on public.weekly_entries;
create policy weekly_entries_select on public.weekly_entries for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos','fichajes']))
  or driver_id = public.linked_driver_id()
);
drop policy if exists weekly_entries_insert on public.weekly_entries;
create policy weekly_entries_insert on public.weekly_entries for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos','fichajes']))
  or driver_id = public.linked_driver_id()
);
drop policy if exists weekly_entries_update on public.weekly_entries;
create policy weekly_entries_update on public.weekly_entries for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos','fichajes']))
  or driver_id = public.linked_driver_id()
);

-- ---------- STORAGE: fichajes/ exige la pestaña "fichajes" o ser conductor ----------
-- (arregla un fallo real: hasta ahora una cuenta de conductor no podía
-- subir la foto del tacógrafo, porque esta política solo miraba
-- trafico/autonomos y nunca el vínculo a un conductor).
create or replace function public.can_access_docs_folder(folder text)
returns boolean
language sql
security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles p where p.id = auth.uid() and (
      p.is_admin
      or (folder = 'attachments' and p.allowed_tabs ?| array['clientes','citas','documentos'])
      or (folder = 'fichajes' and (p.allowed_tabs ?| array['fichajes'] or p.driver_id is not null))
      or folder not in ('attachments','fichajes')
    )
  );
$$;

-- ---------- DRIVERS: se añade "fichajes" como pestaña válida para leer ----------
-- (el detalle de un fichaje muestra el nombre del conductor).
drop policy if exists drivers_select on public.drivers;
create policy drivers_select on public.drivers for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos','fichajes']))
  or id = public.linked_driver_id()
);

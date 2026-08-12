-- ============================================================
-- QUALIFIED PROVEEDORES — cuentas de conductor (solo fichaje)
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, DESPUÉS de roles-schema.sql.
-- ============================================================

alter table public.profiles add column driver_id uuid references public.drivers(id) on delete set null;

create or replace function public.linked_driver_id()
returns uuid
language sql
security definer set search_path = public
as $$
  select driver_id from public.profiles where id = auth.uid();
$$;

-- ---------- DRIVERS: puede leer (no editar) su propia ficha ----------
drop policy if exists drivers_select on public.drivers;
create policy drivers_select on public.drivers for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
  or id = public.linked_driver_id()
);

-- ---------- DAILY_ENTRIES: puede leer/crear/editar solo las suyas ----------
drop policy if exists daily_entries_select on public.daily_entries;
create policy daily_entries_select on public.daily_entries for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
  or driver_id = public.linked_driver_id()
);
drop policy if exists daily_entries_insert on public.daily_entries;
create policy daily_entries_insert on public.daily_entries for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
  or driver_id = public.linked_driver_id()
);
drop policy if exists daily_entries_update on public.daily_entries;
create policy daily_entries_update on public.daily_entries for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
  or driver_id = public.linked_driver_id()
);
-- daily_entries_delete se deja como estaba (solo allowed_tabs/admin) — un
-- conductor puede fichar y cerrar jornada, pero no borrar fichajes.

-- ---------- WEEKLY_ENTRIES: recalcWeeksFromFichajes() las escribe solas ----------
drop policy if exists weekly_entries_select on public.weekly_entries;
create policy weekly_entries_select on public.weekly_entries for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
  or driver_id = public.linked_driver_id()
);
drop policy if exists weekly_entries_insert on public.weekly_entries;
create policy weekly_entries_insert on public.weekly_entries for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
  or driver_id = public.linked_driver_id()
);
drop policy if exists weekly_entries_update on public.weekly_entries;
create policy weekly_entries_update on public.weekly_entries for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
  or driver_id = public.linked_driver_id()
);
-- weekly_entries_delete se deja como estaba (solo allowed_tabs/admin).

-- Nota: driver_rates, fuel_entries, supplement_entries, expense_entries,
-- indexation_entries y companies NO se tocan — un conductor vinculado
-- sigue sin poder verlas ni editarlas bajo ningún concepto, aunque tenga
-- driver_id puesto. Solo ve/edita sus propios fichajes y su propia ficha.

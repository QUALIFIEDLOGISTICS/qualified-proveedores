-- ============================================================
-- QUALIFIED PROVEEDORES — Tráfico incluye ahora la agenda de
-- Direcciones (origen y destino del DeCA). Hasta ahora quien tenía la
-- pestaña Tráfico podía LEER las direcciones pero no crearlas ni
-- editarlas; con esto también puede darlas de alta, cambiarlas y
-- ver su historial. Administración sigue igual.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

drop policy if exists direcciones_insert on public.direcciones;
drop policy if exists direcciones_update on public.direcciones;
drop policy if exists direcciones_delete on public.direcciones;

create policy direcciones_insert on public.direcciones for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','trafico']))
);
create policy direcciones_update on public.direcciones for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','trafico']))
);
create policy direcciones_delete on public.direcciones for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','trafico']))
);

drop policy if exists direccion_historial_select on public.direccion_historial;
drop policy if exists direccion_historial_insert on public.direccion_historial;

create policy direccion_historial_select on public.direccion_historial for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','trafico']))
);
create policy direccion_historial_insert on public.direccion_historial for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','trafico']))
);

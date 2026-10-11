-- =====================================================================
-- Transporte · Configuración: permiso propio.
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
--
-- Ahora la Configuración de Transporte se da aparte en Gestión de Permisos (casilla «Configuración» dentro de
-- Transporte). Pueden modificarla los administradores y quien tenga esa casilla; la leen todos los de Transporte.
-- =====================================================================

drop policy if exists transporte_config_insert on public.transporte_config;
drop policy if exists transporte_config_update on public.transporte_config;
create policy transporte_config_insert on public.transporte_config for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico:configuracion']))
);
create policy transporte_config_update on public.transporte_config for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico:configuracion']))
);

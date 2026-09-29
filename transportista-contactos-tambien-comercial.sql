-- ============================================================
-- QUALIFIED PROVEEDORES — La lista de "Contactos" de una empresa (antes solo
-- en Transporte → Transportistas) ahora también se usa en Comercial →
-- Clientes, así que hay que dejar entrar también a quien tenga la pestaña
-- Comercial (antes solo entraba quien tenía Tráfico).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

drop policy if exists transportista_contactos_select on public.transportista_contactos;
drop policy if exists transportista_contactos_insert on public.transportista_contactos;
drop policy if exists transportista_contactos_update on public.transportista_contactos;
drop policy if exists transportista_contactos_delete on public.transportista_contactos;

create policy transportista_contactos_select on public.transportista_contactos for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','comercial']))
);
create policy transportista_contactos_insert on public.transportista_contactos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','comercial']))
);
create policy transportista_contactos_update on public.transportista_contactos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','comercial']))
);
create policy transportista_contactos_delete on public.transportista_contactos for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico','comercial']))
);

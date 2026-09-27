-- ============================================================
-- QUALIFIED PROVEEDORES — Correo y teléfono de transporte del transportista.
-- Se editan desde Tráfico → Transportistas (una tarjeta aparte, solo esos dos
-- campos); el resto de datos del contacto sigue editándose desde Contactos.
-- También arregla un permiso que faltaba: quien solo tiene la pestaña Tráfico
-- no podía guardar cambios en un contacto marcado como transportista.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.contactos add column if not exists email_transportista text;
alter table public.contactos add column if not exists telefono_transportista text;

drop policy if exists contactos_insert on public.contactos;
drop policy if exists contactos_update on public.contactos;

create policy contactos_insert on public.contactos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['administracion'])
  or (es_cliente_almacen and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['clientes','citas','documentos']))
  or (es_autonomos and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico','autonomos']))
  or (es_transportista and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico']))
  or (es_cliente_transporte and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico']))
  or ((es_cliente_almacen or es_cliente_transporte) and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['comercial']))
);
create policy contactos_update on public.contactos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['administracion'])
  or (es_cliente_almacen and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['clientes','citas','documentos']))
  or (es_autonomos and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico','autonomos']))
  or (es_transportista and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico']))
  or (es_cliente_transporte and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico']))
  or ((es_cliente_almacen or es_cliente_transporte) and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['comercial']))
);

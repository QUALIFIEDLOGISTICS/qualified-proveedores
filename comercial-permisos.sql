-- ============================================================
-- QUALIFIED PROVEEDORES — Módulo Comercial (nueva pestaña "comercial").
-- 1) Quien tenga la pestaña Comercial ve, crea y edita los contactos
--    marcados como cliente (de almacén o de transporte).
-- 2) Puede leer y escribir el historial de esos contactos y subir sus logos.
-- 3) Las tarifas pasan de Tráfico a Comercial: solo administradores y
--    cuentas con la pestaña Comercial las ven y las editan.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

-- Contactos
drop policy if exists contactos_select on public.contactos;
drop policy if exists contactos_insert on public.contactos;
drop policy if exists contactos_update on public.contactos;

create policy contactos_select on public.contactos for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['administracion','trafico'])
  or (es_cliente_almacen and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['clientes','citas','documentos']))
  or (es_autonomos and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico','autonomos']))
  or ((es_cliente_almacen or es_cliente_transporte) and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['comercial']))
);
create policy contactos_insert on public.contactos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['administracion'])
  or (es_cliente_almacen and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['clientes','citas','documentos']))
  or (es_autonomos and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico','autonomos']))
  or (es_cliente_transporte and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico']))
  or ((es_cliente_almacen or es_cliente_transporte) and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['comercial']))
);
create policy contactos_update on public.contactos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['administracion'])
  or (es_cliente_almacen and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['clientes','citas','documentos']))
  or (es_autonomos and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico','autonomos']))
  or (es_cliente_transporte and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico']))
  or ((es_cliente_almacen or es_cliente_transporte) and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['comercial']))
);

-- Historial de cambios de los contactos
drop policy if exists contacto_historial_select on public.contacto_historial;
drop policy if exists contacto_historial_insert on public.contacto_historial;
create policy contacto_historial_select on public.contacto_historial for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos','trafico','autonomos','comercial']))
);
create policy contacto_historial_insert on public.contacto_historial for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','clientes','citas','documentos','trafico','autonomos','comercial']))
);

-- Logos de los contactos (carpeta "logos" del almacenamiento)
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
      or (folder = 'deca' and p.allowed_tabs ?| array['trafico'])
      or (folder = 'logos' and p.allowed_tabs ?| array['administracion','clientes','citas','documentos','trafico','autonomos','comercial'])
      or folder not in ('attachments','fichajes','deca','logos')
    )
  );
$$;

-- Tarifas: de Tráfico a Comercial
drop policy if exists tarifas_select on public.tarifas;
drop policy if exists tarifas_insert on public.tarifas;
drop policy if exists tarifas_update on public.tarifas;
drop policy if exists tarifas_delete on public.tarifas;

create policy tarifas_select on public.tarifas for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['comercial']))
);
create policy tarifas_insert on public.tarifas for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['comercial']))
);
create policy tarifas_update on public.tarifas for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['comercial']))
);
create policy tarifas_delete on public.tarifas for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['comercial']))
);

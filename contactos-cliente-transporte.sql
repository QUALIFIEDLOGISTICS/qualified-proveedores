-- ============================================================
-- QUALIFIED PROVEEDORES — Nuevo rol de contacto: "Cliente de transporte"
-- (los cargadores contractuales del DeCA).
-- 1) Columna nueva es_cliente_transporte en contactos.
-- 2) Marca ya como cliente de transporte a los contactos que hasta ahora
--    usabas como cargador: los que aparecen en algún DeCA (por NIF o por
--    nombre) y los que vinieron de la tabla antigua de cargadores.
--    Así no desaparecen del desplegable del DeCA.
-- 3) Quien tiene la pestaña Tráfico (donde se crea el DeCA) puede crear y
--    editar contactos marcados como cliente de transporte — es lo que hace
--    falta para el botón "+ Crear cargador" del propio DeCA.
--    Leer contactos ya podía; borrar sigue igual.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.contactos add column if not exists es_cliente_transporte boolean not null default false;

update public.contactos c set es_cliente_transporte = true
where exists (
  select 1 from public.deca_documents d
  where (d.cargador_nif is not null and c.nif is not null and upper(d.cargador_nif) = upper(c.nif))
     or upper(d.cargador_nombre) = upper(c.nombre)
);

do $$
begin
  if to_regclass('public.cargadores_contractuales') is not null then
    update public.contactos c set es_cliente_transporte = true
    where exists (
      select 1 from public.cargadores_contractuales g
      where upper(g.nombre) = upper(c.nombre)
         or (g.nif is not null and c.nif is not null and upper(g.nif) = upper(c.nif))
    );
  end if;
end $$;

drop policy if exists contactos_insert on public.contactos;
drop policy if exists contactos_update on public.contactos;

create policy contactos_insert on public.contactos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['administracion'])
  or (es_cliente_almacen and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['clientes','citas','documentos']))
  or (es_autonomos and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico','autonomos']))
  or (es_cliente_transporte and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico']))
);
create policy contactos_update on public.contactos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['administracion'])
  or (es_cliente_almacen and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['clientes','citas','documentos']))
  or (es_autonomos and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico','autonomos']))
  or (es_cliente_transporte and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico']))
);

-- ============================================================
-- QUALIFIED PROVEEDORES — El cargador contractual del DeCA pasa a
-- elegirse entre TODOS los contactos.
-- 1) Quien tiene la pestaña Tráfico (donde está el DeCA) ya puede leer
--    todos los contactos, no solo los marcados como cliente/autónomos.
-- 2) Copia los cargadores contractuales que ya tuvieras a Contactos
--    (sin duplicar los que ya existan con el mismo nombre o NIF).
--    La tabla antigua cargadores_contractuales no se borra.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

drop policy if exists contactos_select on public.contactos;
create policy contactos_select on public.contactos for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['administracion','trafico'])
  or (es_cliente_almacen and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['clientes','citas','documentos']))
  or (es_autonomos and exists (select 1 from public.profiles p where p.id = auth.uid() and p.allowed_tabs ?| array['trafico','autonomos']))
);

insert into public.contactos (nombre, nif, calle1, calle2, codigo_postal, ciudad, provincia, pais)
select upper(g.nombre), upper(g.nif), g.calle1, g.calle2, g.codigo_postal, g.ciudad, g.provincia, g.pais
from public.cargadores_contractuales g
where not exists (
  select 1 from public.contactos c
  where upper(c.nombre) = upper(g.nombre)
     or (g.nif is not null and c.nif is not null and upper(c.nif) = upper(g.nif))
);

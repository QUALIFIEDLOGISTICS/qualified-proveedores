-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Eliminar zonas de un almacén
-- Permite borrar una zona (con sus ubicaciones) en lugar de solo archivarla.
-- Si la zona tiene o ha tenido mercancía, o es la zona habitual de algún artículo, NO se borra
-- (la mercancía no puede quedarse sin sitio): en ese caso se avisa y se puede archivar.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
drop policy if exists sga_zonas_delete on public.sga_zonas;
create policy sga_zonas_delete on public.sga_zonas for delete using (public.sga_permiso('almacenconfig'));
drop policy if exists sga_ubicaciones_delete on public.sga_ubicaciones;
create policy sga_ubicaciones_delete on public.sga_ubicaciones for delete using (public.sga_permiso('almacenconfig'));

create or replace function public.sga_zona_eliminar(p_id uuid) returns void
language plpgsql security invoker set search_path = public as $$
begin
  if not public.sga_permiso('almacenconfig') then
    raise exception 'No tienes permiso para eliminar zonas.';
  end if;
  if exists (select 1 from public.sga_partidas where zona_id = p_id
             or ubicacion_id in (select id from public.sga_ubicaciones where zona_id = p_id)) then
    raise exception 'ZONA_EN_USO: tiene o ha tenido mercancía.';
  end if;
  if exists (select 1 from public.sga_articulos where zona_id = p_id) then
    raise exception 'ZONA_EN_USO: es la zona habitual de algún artículo.';
  end if;
  delete from public.sga_ubicaciones where zona_id = p_id;
  delete from public.sga_zonas where id = p_id;
end $$;
grant execute on function public.sga_zona_eliminar(uuid) to authenticated;

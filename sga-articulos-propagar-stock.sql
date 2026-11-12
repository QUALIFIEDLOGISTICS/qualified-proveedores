-- ============================================================
-- QUALIFIED PROVEEDORES — SGA: lo que se cambia en un artículo del catálogo llega también a su stock
-- Cuando se recibe mercancía, cada palet guarda una COPIA del código, la referencia, el tipo de carga y el tipo de palet de su artículo. Si después se
-- corregía el artículo en el catálogo, esa copia no cambiaba: el inventario enseñaba lo nuevo pero la expedición (y el cobro) seguían con lo viejo.
-- Con esto, al cambiar un artículo se actualiza solo el stock vivo de ese artículo, y solo en los datos que seguían siendo los heredados del artículo
-- (si a un palet se le puso a mano otro valor, ese no se toca). El histórico (palets ya agotados y albaranes) no se modifica.
-- Es seguro ejecutarlo más de una vez. El BLOQUE 1 solo cambia el comportamiento futuro; el BLOQUE 2 (aparte) arregla lo que ya está desalineado.
-- Instrucciones: Supabase → SQL Editor → pega el BLOQUE 1 → Run. Después, si quieres, el BLOQUE 2 (primero la consulta que solo lee).
-- ============================================================

-- ===== BLOQUE 1: al cambiar un artículo, su stock vivo hereda el cambio =====
create or replace function public.sga_articulo_propagar() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.nombre is distinct from old.nombre then
    update public.sga_partidas set descripcion = new.nombre
      where articulo_id = new.id and estado = 'activa' and descripcion is not distinct from old.nombre;
  end if;
  if coalesce(new.referencia, '') <> coalesce(old.referencia, '') then
    update public.sga_partidas set referencia = coalesce(new.referencia, '')
      where articulo_id = new.id and estado = 'activa' and coalesce(referencia, '') = coalesce(old.referencia, '');
  end if;
  if new.producto_id is distinct from old.producto_id then
    update public.sga_partidas set producto_id = new.producto_id
      where articulo_id = new.id and estado = 'activa' and producto_id is not distinct from old.producto_id;
  end if;
  if coalesce(new.atributos->>'subtipo', '') <> coalesce(old.atributos->>'subtipo', '') then
    update public.sga_partidas
      set atributos = case when coalesce(new.atributos->>'subtipo', '') <> ''
                           then coalesce(atributos, '{}'::jsonb) || jsonb_build_object('subtipo', new.atributos->>'subtipo')
                           else coalesce(atributos, '{}'::jsonb) - 'subtipo' end
      where articulo_id = new.id and estado = 'activa' and coalesce(atributos->>'subtipo', '') = coalesce(old.atributos->>'subtipo', '');
  end if;
  return new;
end $$;

drop trigger if exists sga_articulos_propagar on public.sga_articulos;
create trigger sga_articulos_propagar after update on public.sga_articulos for each row execute function public.sga_articulo_propagar();

notify pgrst, 'reload schema';

-- ===== BLOQUE 2a (solo lee): palets en stock cuyos datos ya no coinciden con los de su artículo =====
-- Ejecútalo por separado y mira qué cambiaría el BLOQUE 2b.
-- select k.nombre as cliente, a.nombre as articulo_catalogo, p.descripcion as codigo_en_el_palet, a.referencia as ref_catalogo, p.referencia as ref_en_el_palet,
--        a.producto_id as tipo_carga_catalogo, p.producto_id as tipo_carga_en_el_palet, a.atributos->>'subtipo' as tipo_palet_catalogo, p.atributos->>'subtipo' as tipo_palet_en_el_palet,
--        p.cantidad_actual as palets, coalesce(sc.codigos_unicos, false) as codigo_por_palet
-- from public.sga_partidas p
-- join public.sga_articulos a on a.id = p.articulo_id
-- join public.contactos k on k.id = p.cliente_id
-- left join public.sga_clientes sc on sc.cliente_id = p.cliente_id
-- where p.estado = 'activa' and p.cantidad_actual > 0
--   and ( p.descripcion is distinct from a.nombre
--         or coalesce(p.referencia, '') <> coalesce(a.referencia, '')
--         or (a.producto_id is not null and p.producto_id is distinct from a.producto_id)
--         or (coalesce(a.atributos->>'subtipo', '') <> '' and coalesce(p.atributos->>'subtipo', '') <> coalesce(a.atributos->>'subtipo', '')) )
-- order by k.nombre, a.nombre;

-- ===== BLOQUE 2b (actualiza): alinea el stock vivo con el catálogo, SOLO en clientes que NO llevan un código distinto por cada palet =====
-- (en los clientes con código por palet, la descripción y la referencia de cada palet pueden ser propias: esos no se tocan aquí)
-- update public.sga_partidas p
-- set descripcion = a.nombre,
--     referencia = coalesce(a.referencia, ''),
--     producto_id = coalesce(a.producto_id, p.producto_id),
--     atributos = case when coalesce(a.atributos->>'subtipo', '') <> '' then coalesce(p.atributos, '{}'::jsonb) || jsonb_build_object('subtipo', a.atributos->>'subtipo') else p.atributos end
-- from public.sga_articulos a
-- left join public.sga_clientes sc on sc.cliente_id = a.cliente_id
-- where p.articulo_id = a.id and p.estado = 'activa' and p.cantidad_actual > 0 and coalesce(sc.codigos_unicos, false) = false
--   and ( p.descripcion is distinct from a.nombre
--         or coalesce(p.referencia, '') <> coalesce(a.referencia, '')
--         or (a.producto_id is not null and p.producto_id is distinct from a.producto_id)
--         or (coalesce(a.atributos->>'subtipo', '') <> '' and coalesce(p.atributos->>'subtipo', '') <> coalesce(a.atributos->>'subtipo', '')) );

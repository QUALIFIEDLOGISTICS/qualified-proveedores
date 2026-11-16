-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: unir en UN cliente los que son el mismo con distinto nombre de granja (plantilla para repetir con cualquier cliente)
-- Cambia SOLO las dos líneas marcadas con «CAMBIA»:
--   v_patron → el principio del nombre, con % al final (ej.  'NOMBRE DEL CLIENTE%' ). Debe encontrar a todos los que son el mismo cliente y a nadie más.
--   v_nuevo  → el nombre correcto con el que se queda el cliente (sin la granja).
-- Qué hace (en una sola operación: si algo falla, no cambia nada):
--   1) A cada viaje le apunta en sus Notas el nombre de la granja o lugar que llevaba el cliente, y su teléfono si era distinto.
--   2) Pasa todos los viajes al cliente que más viajes tiene (el principal) y le pone el nombre correcto.
--   3) Archiva (NO borra) los demás, con una nota de a quién se unieron.
-- Si no encuentra al menos 2 clientes activos con ese principio de nombre, no hace nada (por eso, ejecutado dos veces, la segunda no repite nada).
-- Antes: ejecuta el BLOQUE A para ver a quiénes va a unir. Instrucciones: Supabase → SQL Editor → cada bloque por separado.
-- ============================================================

-- BLOQUE A (solo lee): los clientes activos que se unirían (cambia el patrón igual que abajo)
select c.id, c.nombre, c.telefono, c.forma_pago, count(v.id) as viajes
from public.forraje_clientes c
left join public.forraje_viajes v on v.cliente_id = c.id
where not c.archived and c.nombre ilike 'PARTE_DEL_NOMBRE%'   -- CAMBIA
group by c.id
order by viajes desc, c.nombre;

-- BLOQUE B (el cambio)
do $$
declare
  v_patron text := 'PARTE_DEL_NOMBRE%';   -- CAMBIA
  v_nuevo  text := 'NOMBRE_CORRECTO';     -- CAMBIA
  v_p public.forraje_clientes%rowtype;
  v_ids uuid[];
  v_n int;
begin
  select array_agg(id) into v_ids from public.forraje_clientes where not archived and nombre ilike v_patron;
  if coalesce(array_length(v_ids, 1), 0) < 2 then raise exception 'Hay menos de 2 clientes activos con ese principio de nombre: no hay nada que unir.'; end if;

  -- el principal: el que más viajes tiene (si empatan, el más antiguo)
  select c.* into v_p from public.forraje_clientes c where c.id = any(v_ids)
  order by (select count(*) from public.forraje_viajes v where v.cliente_id = c.id) desc, c.created_at limit 1;
  if exists (select 1 from public.forraje_clientes where lower(nombre) = lower(v_nuevo) and id <> v_p.id) then
    raise exception 'Ya existe otro cliente llamado «%»: elige otro nombre o únelo primero.', v_nuevo;
  end if;

  -- 1) lo que había detrás del nombre pasa a las Notas de cada viaje
  update public.forraje_viajes v set notas = concat_ws(' · ', nullif(trim(v.notas), ''),
      'Lugar de descarga: ' || coalesce(nullif(trim(both ' -' from case when lower(c.nombre) like lower(v_nuevo) || '%' then substr(c.nombre, length(v_nuevo) + 1) else c.nombre end), ''), c.nombre),
      case when coalesce(c.telefono, '') <> coalesce(v_p.telefono, '') and coalesce(c.telefono, '') <> '' then 'Tel. ' || c.telefono end)
  from public.forraje_clientes c
  where c.id = v.cliente_id and c.id = any(v_ids) and lower(c.nombre) <> lower(v_nuevo);
  get diagnostics v_n = row_count;
  raise notice 'Viajes con la granja anotada en sus notas: %', v_n;

  -- 2) todos los viajes pasan al principal
  update public.forraje_viajes set cliente_id = v_p.id where cliente_id = any(v_ids) and cliente_id <> v_p.id;

  -- 3) los demás se archivan (no se borran)
  update public.forraje_clientes set archived = true,
      notas = concat_ws(' · ', nullif(trim(notas), ''), 'Unido al cliente «' || v_nuevo || '»')
  where id = any(v_ids) and id <> v_p.id;

  -- 4) el principal se queda con el nombre correcto
  update public.forraje_clientes set nombre = v_nuevo where id = v_p.id;
end $$;

-- COMPROBACIÓN (solo lee): el principal con todos los viajes y los demás archivados con 0
select c.nombre, c.archived, count(v.id) as viajes
from public.forraje_clientes c
left join public.forraje_viajes v on v.cliente_id = c.id
where c.nombre ilike 'PARTE_DEL_NOMBRE%' or c.notas ilike '%Unido al cliente «NOMBRE_CORRECTO»%'   -- CAMBIA (los dos)
group by c.id
order by c.archived, c.nombre;

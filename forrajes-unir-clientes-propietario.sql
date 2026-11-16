-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: unir en UN cliente varias granjas del mismo propietario (por identificador; nombres del tipo «GRANJA X (PUEBLO) - PROPIETARIO»)
-- Cambia las líneas marcadas con «CAMBIA»: los identificadores (el principal y la lista) y v_nuevo (el nombre con el que se queda el cliente).
-- Qué hace (en una sola operación: si algo falla, no cambia nada):
--   1) A cada viaje le apunta en sus Notas la granja (el nombre sin « - PROPIETARIO» del final) y el teléfono de esa granja si tenía.
--   2) Pasa todos los viajes al cliente principal y le pone el nombre correcto.
--   3) Archiva (NO borra) las demás fichas, con una nota de a quién se unieron.
-- Se puede ejecutar más de una vez sin que nada se duplique.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Después ejecuta la comprobación del final.
-- ============================================================
do $$
declare
  v_principal uuid := 'da91ee47-9677-4ffb-aa1e-05ccea627240';   -- CAMBIA: el que se queda (el de más viajes)
  v_ids uuid[] := array[                                         -- CAMBIA: todos los que se unen, incluido el principal
    '0edb08b1-09dd-438e-b2e8-17520f132f0d',
    'da91ee47-9677-4ffb-aa1e-05ccea627240',
    '298618f5-5108-4dd8-9d0f-efaddc1cc983'
  ]::uuid[];
  v_nuevo text := 'NOMBRE_DEL_PROPIETARIO';                       -- CAMBIA: el nombre con el que se queda
  v_p public.forraje_clientes%rowtype;
  v_n int;
begin
  select * into v_p from public.forraje_clientes where id = v_principal;
  if not found then raise exception 'No existe el cliente principal.'; end if;
  if (select count(*) from public.forraje_clientes where id = any(v_ids)) <> array_length(v_ids, 1) then
    raise exception 'Alguno de los clientes a unir no existe.';
  end if;
  if exists (select 1 from public.forraje_clientes where lower(nombre) = lower(v_nuevo) and id <> v_principal) then
    raise exception 'Ya existe otro cliente llamado «%»: elige otro nombre.', v_nuevo;
  end if;

  update public.forraje_viajes v set notas = concat_ws(' · ', nullif(trim(v.notas), ''),
      'Lugar de descarga: ' || coalesce(nullif(trim(regexp_replace(c.nombre, '\s*-\s*' || v_nuevo || '\s*$', '', 'i')), ''), c.nombre),
      case when coalesce(c.telefono, '') <> coalesce(v_p.telefono, '') and coalesce(c.telefono, '') <> '' then 'Tel. ' || c.telefono end)
  from public.forraje_clientes c
  where c.id = v.cliente_id and c.id = any(v_ids) and lower(c.nombre) <> lower(v_nuevo);
  get diagnostics v_n = row_count;
  raise notice 'Viajes con la granja anotada en sus notas: %', v_n;

  update public.forraje_viajes set cliente_id = v_principal where cliente_id = any(v_ids) and cliente_id <> v_principal;

  update public.forraje_clientes set archived = true,
      notas = concat_ws(' · ', nullif(trim(notas), ''), 'Unido al cliente «' || v_nuevo || '»')
  where id = any(v_ids) and id <> v_principal;

  update public.forraje_clientes set nombre = v_nuevo where id = v_principal;
end $$;

-- COMPROBACIÓN (solo lee): el principal con todos los viajes y las demás fichas archivadas con 0
select c.nombre, c.archived, count(v.id) as viajes
from public.forraje_clientes c
left join public.forraje_viajes v on v.cliente_id = c.id
where c.id in ('0edb08b1-09dd-438e-b2e8-17520f132f0d', 'da91ee47-9677-4ffb-aa1e-05ccea627240', '298618f5-5108-4dd8-9d0f-efaddc1cc983')   -- CAMBIA
group by c.id
order by c.archived, c.nombre;

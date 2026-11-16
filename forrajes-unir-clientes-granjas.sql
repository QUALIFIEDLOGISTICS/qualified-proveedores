-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: unir en UN cliente los que son el mismo con distinto nombre de granja
-- Qué hace (en una sola operación: si algo falla, no cambia nada):
--   1) A cada viaje de los clientes a unir le apunta, en sus Notas, lo que había detrás del nombre (la granja o el lugar), y su teléfono si era distinto.
--   2) Pasa todos esos viajes al cliente principal.
--   3) Archiva (NO borra) los clientes que sobran, con una nota de a quién se unieron.
-- Antes de tocar nada comprueba que todos existen y que su nombre empieza igual que el del principal.
-- Se puede ejecutar más de una vez sin que nada se duplique (la segunda vez no encuentra viajes que mover).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Después ejecuta la comprobación del final.
-- ============================================================
do $$
declare
  v_principal uuid := 'a80f91cd-0894-4757-870c-91582bbc6234';
  v_otros uuid[] := array[
    'c3b205a0-0eea-4570-af81-6cde48db2251',
    '948a3cf6-78f5-4281-97a2-0bacb423d9c4',
    '32c9df1c-f8d0-413e-9cc8-3858460c6c39',
    'a1ab7986-a137-4645-8109-23edfaa179dd',
    '55a59290-8bda-4cbf-872c-fd56ea0074cc',
    'bd734e0e-dc5d-4c00-8cc0-a8dbc362a976'
  ]::uuid[];
  v_p public.forraje_clientes%rowtype;
  v_n int;
begin
  select * into v_p from public.forraje_clientes where id = v_principal;
  if not found then raise exception 'No existe el cliente principal.'; end if;
  if (select count(*) from public.forraje_clientes where id = any(v_otros)) <> array_length(v_otros, 1) then
    raise exception 'Alguno de los clientes a unir no existe.';
  end if;
  if exists (select 1 from public.forraje_clientes where id = any(v_otros) and lower(nombre) not like lower(v_p.nombre) || '%') then
    raise exception 'Alguno de los clientes a unir no empieza igual que el principal: no se cambia nada.';
  end if;

  -- 1) lo que había detrás del nombre pasa a las Notas de cada viaje
  update public.forraje_viajes v set notas = concat_ws(' · ', nullif(trim(v.notas), ''),
      'Lugar de descarga: ' || coalesce(nullif(trim(both ' -' from substr(c.nombre, length(v_p.nombre) + 1)), ''), c.nombre),
      case when coalesce(c.telefono, '') <> coalesce(v_p.telefono, '') and coalesce(c.telefono, '') <> '' then 'Tel. ' || c.telefono end)
  from public.forraje_clientes c
  where c.id = v.cliente_id and c.id = any(v_otros);
  get diagnostics v_n = row_count;
  raise notice 'Viajes con la granja anotada en sus notas: %', v_n;

  -- 2) todos esos viajes pasan al cliente principal
  update public.forraje_viajes set cliente_id = v_principal where cliente_id = any(v_otros);

  -- 3) los clientes que sobran se archivan (no se borran)
  update public.forraje_clientes set archived = true,
      notas = concat_ws(' · ', nullif(trim(notas), ''), 'Unido al cliente «' || v_p.nombre || '»')
  where id = any(v_otros);
end $$;

-- COMPROBACIÓN (solo lee): el principal debe tener la suma de todos los viajes y los demás, 0 y archivados
select c.nombre, c.archived, count(v.id) as viajes
from public.forraje_clientes c
left join public.forraje_viajes v on v.cliente_id = c.id
where c.id in ('a80f91cd-0894-4757-870c-91582bbc6234', 'c3b205a0-0eea-4570-af81-6cde48db2251', '948a3cf6-78f5-4281-97a2-0bacb423d9c4', '32c9df1c-f8d0-413e-9cc8-3858460c6c39',
               'a1ab7986-a137-4645-8109-23edfaa179dd', '55a59290-8bda-4cbf-872c-fd56ea0074cc', 'bd734e0e-dc5d-4c00-8cc0-a8dbc362a976')
group by c.id
order by c.archived, c.nombre;

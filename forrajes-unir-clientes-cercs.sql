-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: unir dos clientes que son el mismo (por identificador)
-- Qué hace (en una sola operación: si algo falla, no cambia nada):
--   1) A cada viaje del cliente que sobra le apunta en sus Notas el nombre que llevaba (y su teléfono si era distinto).
--   2) Pasa esos viajes al cliente principal.
--   3) Archiva (NO borra) el cliente que sobra, con una nota de a quién se unió.
-- Se puede ejecutar más de una vez sin que nada se duplique (la segunda vez no encuentra viajes que mover).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Después ejecuta la comprobación del final.
-- ============================================================
do $$
declare
  v_principal uuid := '0fa63a46-4c6a-4c3c-8ede-f6e509b06356';
  v_otros uuid[] := array['3afe71ba-d7c2-4bdd-bffb-d9a5703ff109']::uuid[];
  v_p public.forraje_clientes%rowtype;
  v_n int;
begin
  select * into v_p from public.forraje_clientes where id = v_principal;
  if not found then raise exception 'No existe el cliente principal.'; end if;
  if (select count(*) from public.forraje_clientes where id = any(v_otros)) <> array_length(v_otros, 1) then
    raise exception 'Alguno de los clientes a unir no existe.';
  end if;

  update public.forraje_viajes v set notas = concat_ws(' · ', nullif(trim(v.notas), ''),
      'Lugar de descarga: ' || c.nombre,
      case when coalesce(c.telefono, '') <> coalesce(v_p.telefono, '') and coalesce(c.telefono, '') <> '' then 'Tel. ' || c.telefono end)
  from public.forraje_clientes c
  where c.id = v.cliente_id and c.id = any(v_otros);
  get diagnostics v_n = row_count;
  raise notice 'Viajes con el nombre anotado en sus notas: %', v_n;

  update public.forraje_viajes set cliente_id = v_principal where cliente_id = any(v_otros);

  update public.forraje_clientes set archived = true,
      notas = concat_ws(' · ', nullif(trim(notas), ''), 'Unido al cliente «' || v_p.nombre || '»')
  where id = any(v_otros);
end $$;

-- COMPROBACIÓN (solo lee): el principal con todos los viajes y el otro archivado con 0
select c.nombre, c.archived, count(v.id) as viajes
from public.forraje_clientes c
left join public.forraje_viajes v on v.cliente_id = c.id
where c.id in ('0fa63a46-4c6a-4c3c-8ede-f6e509b06356', '3afe71ba-d7c2-4bdd-bffb-d9a5703ff109')
group by c.id
order by c.archived, c.nombre;

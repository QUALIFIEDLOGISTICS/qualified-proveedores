-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Confirmar una entrada (todo o nada)
-- Crea de golpe, en UNA sola operación: el albarán de entrada, las partidas (el stock),
-- el libro de movimientos, los servicios anotados y los cobros calculados.
-- Si algo falla (por ejemplo un código de palet repetido), no se guarda NADA.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
create or replace function public.sga_confirmar_entrada(p jsonb) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  a jsonb := p->'albaran';
  v_albaran uuid;
  v_partida uuid;
  v_fecha date := (a->>'fecha')::date;
  v_tipo text := coalesce(nullif(a->>'tipo', ''), 'entrada');
  r jsonb;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para registrar entradas.';
  end if;
  if jsonb_array_length(coalesce(p->'partidas', '[]'::jsonb)) = 0 then
    raise exception 'La entrada no tiene mercancía.';
  end if;

  insert into public.sga_albaranes (created_by, tipo, cliente_id, warehouse_id, fecha, referencia, modalidad, transportista, matricula, observaciones, estado, confirmado_at)
  values (a->>'created_by', v_tipo, (a->>'cliente_id')::uuid, a->>'warehouse_id', v_fecha,
          nullif(a->>'referencia', ''), coalesce(nullif(a->>'modalidad', ''), 'palet'),
          nullif(a->>'transportista', ''), nullif(a->>'matricula', ''), nullif(a->>'observaciones', ''), 'confirmado', now())
  returning id into v_albaran;

  for r in select value from jsonb_array_elements(p->'partidas') loop
    insert into public.sga_partidas (cliente_id, warehouse_id, zona_id, ubicacion_id, producto_id, referencia, descripcion, lote, codigo,
                                     cantidad_inicial, cantidad_actual, fecha_entrada, albaran_entrada_id, atributos)
    values ((a->>'cliente_id')::uuid, a->>'warehouse_id', nullif(r->>'zona_id', '')::uuid, nullif(r->>'ubicacion_id', '')::uuid, r->>'producto_id',
            nullif(r->>'referencia', ''), nullif(r->>'descripcion', ''), nullif(r->>'lote', ''), nullif(r->>'codigo', ''),
            (r->>'cantidad')::int, (r->>'cantidad')::int, v_fecha, v_albaran, coalesce(r->'atributos', '{}'::jsonb))
    returning id into v_partida;

    insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha)
    values (a->>'created_by', v_partida, v_albaran, v_tipo, (r->>'cantidad')::int, v_fecha);
  end loop;

  for r in select value from jsonb_array_elements(coalesce(p->'servicios', '[]'::jsonb)) loop
    insert into public.sga_servicios (albaran_id, producto_id, cantidad, nota)
    values (v_albaran, r->>'producto_id', (r->>'cantidad')::numeric, nullif(r->>'nota', ''));
  end loop;

  for r in select value from jsonb_array_elements(coalesce(p->'cobros', '[]'::jsonb)) loop
    insert into public.sga_cobros (cliente_id, albaran_id, fecha, periodo, origen, producto_id, subtipo, cantidad, precio, importe, tarifa_id, nota)
    values ((a->>'cliente_id')::uuid, v_albaran, v_fecha, to_char(v_fecha, 'YYYY-MM'), r->>'origen', r->>'producto_id', nullif(r->>'subtipo', ''),
            (r->>'cantidad')::numeric, (r->>'precio')::numeric, (r->>'importe')::numeric, nullif(r->>'tarifa_id', '')::uuid, nullif(r->>'nota', ''));
  end loop;

  return v_albaran;
end $$;

notify pgrst, 'reload schema';

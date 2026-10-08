-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Confirmar una salida (todo o nada)
-- Crea de golpe, en UNA sola operación: el albarán de salida, el descuento de stock de cada partida,
-- el libro de movimientos (cantidades en negativo), los servicios y los cobros.
-- Bloquea cada partida mientras trabaja y comprueba que queda stock: si dos personas sacan lo mismo a la vez,
-- la segunda recibe un aviso y no se guarda nada.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
create or replace function public.sga_confirmar_salida(p jsonb) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  a jsonb := p->'albaran';
  v_albaran uuid;
  v_fecha date := (a->>'fecha')::date;
  v_cli uuid := (a->>'cliente_id')::uuid;
  v_actual int;
  v_cant int;
  r jsonb;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para registrar salidas.';
  end if;
  if jsonb_array_length(coalesce(p->'salidas', '[]'::jsonb)) = 0 then
    raise exception 'La salida no tiene mercancía.';
  end if;

  insert into public.sga_albaranes (created_by, tipo, cliente_id, warehouse_id, fecha, referencia, modalidad, transportista, matricula, observaciones, estado, confirmado_at)
  values (a->>'created_by', 'salida', v_cli, a->>'warehouse_id', v_fecha,
          nullif(a->>'referencia', ''), coalesce(nullif(a->>'modalidad', ''), 'palet'),
          nullif(a->>'transportista', ''), nullif(a->>'matricula', ''), nullif(a->>'observaciones', ''), 'confirmado', now())
  returning id into v_albaran;

  for r in select value from jsonb_array_elements(p->'salidas') loop
    v_cant := (r->>'cantidad')::int;
    select cantidad_actual into v_actual from public.sga_partidas
      where id = (r->>'partida_id')::uuid and cliente_id = v_cli for update;
    if not found then
      raise exception 'Una de las partidas ya no existe o no es de este cliente. Recarga la pantalla.';
    end if;
    if v_actual < v_cant then
      raise exception 'Ya no queda stock suficiente en una partida (quedan %, se pedían %). Recarga la pantalla.', v_actual, v_cant;
    end if;
    update public.sga_partidas
      set cantidad_actual = cantidad_actual - v_cant,
          estado = case when cantidad_actual - v_cant = 0 then 'agotada' else estado end
      where id = (r->>'partida_id')::uuid;
    insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, fifo_saltado)
    values (a->>'created_by', (r->>'partida_id')::uuid, v_albaran, 'salida', -v_cant, v_fecha, coalesce((r->>'fifo_saltado')::boolean, false));
  end loop;

  for r in select value from jsonb_array_elements(coalesce(p->'servicios', '[]'::jsonb)) loop
    insert into public.sga_servicios (albaran_id, producto_id, cantidad, nota)
    values (v_albaran, r->>'producto_id', (r->>'cantidad')::numeric, nullif(r->>'nota', ''));
  end loop;

  for r in select value from jsonb_array_elements(coalesce(p->'cobros', '[]'::jsonb)) loop
    insert into public.sga_cobros (cliente_id, albaran_id, fecha, periodo, origen, producto_id, subtipo, cantidad, precio, importe, tarifa_id, nota)
    values (v_cli, v_albaran, v_fecha, to_char(v_fecha, 'YYYY-MM'), r->>'origen', r->>'producto_id', nullif(r->>'subtipo', ''),
            (r->>'cantidad')::numeric, (r->>'precio')::numeric, (r->>'importe')::numeric, nullif(r->>'tarifa_id', '')::uuid, nullif(r->>'nota', ''));
  end loop;

  return v_albaran;
end $$;

notify pgrst, 'reload schema';

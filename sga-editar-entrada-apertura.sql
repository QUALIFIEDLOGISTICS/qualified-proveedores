-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Editar una entrada o un stock inicial y recalcularlo todo
-- En UNA sola operación (todo o nada):
--   · Las líneas que ya existían se actualizan EN SU SITIO (conservan su partida, así que las salidas ya hechas siguen enlazadas).
--   · Las líneas nuevas crean su partida y su movimiento.
--   · Las líneas quitadas solo se pueden quitar si no ha salido nada de ellas.
--   · Los servicios y los cobros de la entrada se rehacen con los datos nuevos.
--   · El albarán conserva su número y se actualizan sus datos (fecha, referencia, transportista…).
-- No se puede dejar una línea con menos palets de los que ya han salido, ni editar una entrada anulada
-- o cuyos cobros ya estén «facturados».
-- Esta versión también deja editar el STOCK INICIAL (apertura), que antes no se podía. Sustituye a la función anterior.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================

create or replace function public.sga_editar_entrada(p_id uuid, p jsonb) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  a jsonb := p->'albaran';
  alb public.sga_albaranes%rowtype;
  pt public.sga_partidas%rowtype;
  v_fecha date := (a->>'fecha')::date;
  v_cli uuid;
  v_cant int;
  v_cons int;
  v_partida uuid;
  v_tipo text;
  r jsonb;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para editar entradas.';
  end if;

  select * into alb from public.sga_albaranes where id = p_id for update;
  if not found then raise exception 'El albarán no existe.'; end if;
  if alb.tipo not in ('entrada', 'apertura') then raise exception 'Solo se pueden editar entradas y stocks iniciales.'; end if;
  v_tipo := alb.tipo;
  if alb.estado <> 'confirmado' then raise exception 'Esta entrada está anulada: no se puede editar.'; end if;
  if exists (select 1 from public.sga_cobros where albaran_id = p_id and estado = 'facturado') then
    raise exception 'Esta entrada ya está facturada: no se puede editar.';
  end if;
  v_cli := alb.cliente_id;
  if (a->>'cliente_id')::uuid <> v_cli then raise exception 'El cliente de una entrada no se puede cambiar.'; end if;
  if jsonb_array_length(coalesce(p->'partidas', '[]'::jsonb)) = 0 then
    raise exception 'La entrada no tiene mercancía.';
  end if;

  -- 1) Líneas quitadas: solo si no ha salido nada de ellas
  for pt in select * from public.sga_partidas where albaran_entrada_id = p_id for update loop
    if not exists (select 1 from jsonb_array_elements(p->'partidas') e where nullif(e->>'id', '') = pt.id::text) then
      if pt.cantidad_actual <> pt.cantidad_inicial then
        raise exception 'No se puede quitar una línea de la que ya ha salido mercancía.';
      end if;
      delete from public.sga_movimientos where partida_id = pt.id;
      delete from public.sga_partidas where id = pt.id;
    end if;
  end loop;

  -- 2) Líneas: se actualizan las que existían y se crean las nuevas
  for r in select value from jsonb_array_elements(p->'partidas') loop
    v_cant := (r->>'cantidad')::int;
    if nullif(r->>'id', '') is not null then
      select * into pt from public.sga_partidas where id = (r->>'id')::uuid and albaran_entrada_id = p_id for update;
      if not found then raise exception 'Una de las líneas ya no existe. Recarga la pantalla.'; end if;
      v_cons := pt.cantidad_inicial - pt.cantidad_actual;      -- lo que ya ha salido de esta línea
      if v_cant < v_cons then
        raise exception 'De una línea ya han salido % palets: no puede quedar con menos.', v_cons;
      end if;
      update public.sga_partidas
        set warehouse_id = a->>'warehouse_id',
            zona_id = nullif(r->>'zona_id', '')::uuid, ubicacion_id = nullif(r->>'ubicacion_id', '')::uuid,
            producto_id = r->>'producto_id', referencia = nullif(r->>'referencia', ''), descripcion = nullif(r->>'descripcion', ''),
            lote = nullif(r->>'lote', ''), codigo = nullif(r->>'codigo', ''),
            cantidad_inicial = v_cant, cantidad_actual = v_cant - v_cons,
            estado = case when v_cant - v_cons = 0 then 'agotada' else 'activa' end,
            fecha_entrada = v_fecha, atributos = coalesce(r->'atributos', '{}'::jsonb),
            articulo_id = nullif(r->>'articulo_id', '')::uuid, bultos = nullif(r->>'bultos', '')::numeric
        where id = pt.id;
      update public.sga_movimientos
        set cantidad = v_cant, fecha = v_fecha, bultos = nullif(r->>'bultos', '')::numeric
        where partida_id = pt.id and albaran_id = p_id and tipo = v_tipo;
    else
      insert into public.sga_partidas (cliente_id, warehouse_id, zona_id, ubicacion_id, producto_id, referencia, descripcion, lote, codigo,
                                       cantidad_inicial, cantidad_actual, fecha_entrada, albaran_entrada_id, atributos, articulo_id, bultos)
      values (v_cli, a->>'warehouse_id', nullif(r->>'zona_id', '')::uuid, nullif(r->>'ubicacion_id', '')::uuid, r->>'producto_id',
              nullif(r->>'referencia', ''), nullif(r->>'descripcion', ''), nullif(r->>'lote', ''), nullif(r->>'codigo', ''),
              v_cant, v_cant, v_fecha, p_id, coalesce(r->'atributos', '{}'::jsonb),
              nullif(r->>'articulo_id', '')::uuid, nullif(r->>'bultos', '')::numeric)
      returning id into v_partida;
      insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, bultos)
      values (a->>'created_by', v_partida, p_id, v_tipo, v_cant, v_fecha, nullif(r->>'bultos', '')::numeric);
    end if;
  end loop;

  -- 3) Servicios y cobros: se rehacen
  delete from public.sga_servicios where albaran_id = p_id;
  delete from public.sga_cobros where albaran_id = p_id;
  for r in select value from jsonb_array_elements(coalesce(p->'servicios', '[]'::jsonb)) loop
    insert into public.sga_servicios (albaran_id, producto_id, cantidad, nota)
    values (p_id, r->>'producto_id', (r->>'cantidad')::numeric, nullif(r->>'nota', ''));
  end loop;
  for r in select value from jsonb_array_elements(coalesce(p->'cobros', '[]'::jsonb)) loop
    insert into public.sga_cobros (cliente_id, albaran_id, fecha, periodo, origen, producto_id, subtipo, cantidad, precio, importe, tarifa_id, nota)
    values (v_cli, p_id, v_fecha, to_char(v_fecha, 'YYYY-MM'), r->>'origen', r->>'producto_id', nullif(r->>'subtipo', ''),
            (r->>'cantidad')::numeric, (r->>'precio')::numeric, (r->>'importe')::numeric, nullif(r->>'tarifa_id', '')::uuid, nullif(r->>'nota', ''));
  end loop;

  -- 4) Datos del albarán
  update public.sga_albaranes
    set warehouse_id = a->>'warehouse_id', fecha = v_fecha,
        referencia = nullif(a->>'referencia', ''), modalidad = coalesce(nullif(a->>'modalidad', ''), 'palet'),
        transportista = nullif(a->>'transportista', ''), matricula = nullif(a->>'matricula', ''), observaciones = nullif(a->>'observaciones', ''),
        editado_at = now(), editado_por = a->>'created_by'
    where id = p_id;

  return p_id;
end $$;

alter table public.sga_albaranes add column if not exists editado_at timestamptz;
alter table public.sga_albaranes add column if not exists editado_por text;

notify pgrst, 'reload schema';

-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Editar una salida y recalcularlo todo
-- En UNA sola operación (todo o nada):
--   1) deshace la salida anterior: devuelve el stock a las partidas y borra sus movimientos, servicios y cobros;
--   2) aplica la salida corregida igual que al confirmarla (descuenta stock, movimientos, servicios y cobros nuevos);
--   3) actualiza los datos del albarán (fecha, referencia, destinatario…). El albarán conserva su número.
-- No se puede editar una salida anulada ni una cuyos cobros ya están «facturados».
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================

alter table public.sga_albaranes add column if not exists editado_at timestamptz;
alter table public.sga_albaranes add column if not exists editado_por text;

create or replace function public.sga_editar_salida(p_id uuid, p jsonb) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  a jsonb := p->'albaran';
  alb public.sga_albaranes%rowtype;
  pt public.sga_partidas%rowtype;
  mv record;
  v_fecha date := (a->>'fecha')::date;
  v_cli uuid;
  v_actual int;
  v_cant int;
  v_bultos numeric;
  r jsonb;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para editar salidas.';
  end if;

  select * into alb from public.sga_albaranes where id = p_id for update;
  if not found then raise exception 'El albarán no existe.'; end if;
  if alb.tipo <> 'salida' then raise exception 'Solo se pueden editar salidas.'; end if;
  if alb.estado <> 'confirmado' then raise exception 'Esta salida está anulada: no se puede editar.'; end if;
  if exists (select 1 from public.sga_cobros where albaran_id = p_id and estado = 'facturado') then
    raise exception 'Esta salida ya está facturada: no se puede editar.';
  end if;
  v_cli := alb.cliente_id;
  if (a->>'cliente_id')::uuid <> v_cli then raise exception 'El cliente de una salida no se puede cambiar.'; end if;
  if jsonb_array_length(coalesce(p->'salidas', '[]'::jsonb)) = 0 then
    raise exception 'La salida no tiene mercancía.';
  end if;

  -- 1) Deshacer la salida anterior
  for mv in select * from public.sga_movimientos where albaran_id = p_id and tipo = 'salida' loop
    select * into pt from public.sga_partidas where id = mv.partida_id for update;
    if not found or pt.estado = 'anulada' then
      raise exception 'No se puede editar: la entrada de parte de esta mercancía está anulada.';
    end if;
    update public.sga_partidas
      set cantidad_actual = cantidad_actual - mv.cantidad,      -- mv.cantidad es negativa: se devuelve
          estado = 'activa'
      where id = pt.id;
  end loop;
  delete from public.sga_movimientos where albaran_id = p_id and tipo = 'salida';
  delete from public.sga_servicios where albaran_id = p_id;
  delete from public.sga_cobros where albaran_id = p_id;

  -- 2) Aplicar la salida corregida
  for r in select value from jsonb_array_elements(p->'salidas') loop
    v_cant := (r->>'cantidad')::int;
    v_bultos := nullif(r->>'bultos', '')::numeric;
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
          estado = case when cantidad_actual - v_cant = 0 then 'agotada' else 'activa' end
      where id = (r->>'partida_id')::uuid;
    insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, fifo_saltado, bultos)
    values (a->>'created_by', (r->>'partida_id')::uuid, p_id, 'salida', -v_cant, v_fecha, coalesce((r->>'fifo_saltado')::boolean, false),
            case when v_bultos is null then null else -v_bultos end);
  end loop;

  for r in select value from jsonb_array_elements(coalesce(p->'servicios', '[]'::jsonb)) loop
    insert into public.sga_servicios (albaran_id, producto_id, cantidad, nota)
    values (p_id, r->>'producto_id', (r->>'cantidad')::numeric, nullif(r->>'nota', ''));
  end loop;

  for r in select value from jsonb_array_elements(coalesce(p->'cobros', '[]'::jsonb)) loop
    insert into public.sga_cobros (cliente_id, albaran_id, fecha, periodo, origen, producto_id, subtipo, cantidad, precio, importe, tarifa_id, nota)
    values (v_cli, p_id, v_fecha, to_char(v_fecha, 'YYYY-MM'), r->>'origen', r->>'producto_id', nullif(r->>'subtipo', ''),
            (r->>'cantidad')::numeric, (r->>'precio')::numeric, (r->>'importe')::numeric, nullif(r->>'tarifa_id', '')::uuid, nullif(r->>'nota', ''));
  end loop;

  -- 3) Datos del albarán
  update public.sga_albaranes
    set warehouse_id = a->>'warehouse_id', fecha = v_fecha,
        referencia = nullif(a->>'referencia', ''), modalidad = coalesce(nullif(a->>'modalidad', ''), 'palet'),
        transportista = nullif(a->>'transportista', ''), matricula = nullif(a->>'matricula', ''), observaciones = nullif(a->>'observaciones', ''),
        destinatario = nullif(a->>'destinatario', ''), destinatario_direccion = nullif(a->>'destinatario_direccion', ''),
        editado_at = now(), editado_por = a->>'created_by'
    where id = p_id;

  return p_id;
end $$;

notify pgrst, 'reload schema';

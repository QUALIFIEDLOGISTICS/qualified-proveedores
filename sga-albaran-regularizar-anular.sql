-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Albarán de salida numerado, regularizaciones y anulación de albaranes
--  • Nº de albarán de salida: 3 letras del cliente + fecha (DDMMAAAA) + orden de la salida del día. Ej. GLO08102026-1
--  • Destinatario («PARA:») de cada salida.
--  • Regularizar stock (ajustar a lo que realmente hay), dejando constancia y motivo.
--  • Anular un albarán equivocado: el stock vuelve a como estaba, el albarán queda marcado y sus cobros anulados.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.sga_clientes add column if not exists prefijo text;                -- 3 letras para el nº de albarán
alter table public.sga_albaranes add column if not exists numero_texto text;           -- GLO08102026-1
alter table public.sga_albaranes add column if not exists destinatario text;
alter table public.sga_albaranes add column if not exists destinatario_direccion text;
create unique index if not exists sga_albaranes_numero_texto_unico on public.sga_albaranes (cliente_id, numero_texto) where numero_texto is not null;

-- El tipo de albarán admite también «regularizacion»
alter table public.sga_albaranes drop constraint if exists sga_albaranes_tipo_check;
alter table public.sga_albaranes add constraint sga_albaranes_tipo_check check (tipo in ('entrada', 'salida', 'apertura', 'regularizacion'));

-- ---------- Confirmar salida (con nº de albarán y destinatario) ----------
create or replace function public.sga_confirmar_salida(p jsonb) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  a jsonb := p->'albaran';
  v_albaran uuid;
  v_fecha date := (a->>'fecha')::date;
  v_cli uuid := (a->>'cliente_id')::uuid;
  v_actual int;
  v_cant int;
  v_bultos numeric;
  v_pref text;
  v_seq int;
  r jsonb;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para registrar salidas.';
  end if;
  if jsonb_array_length(coalesce(p->'salidas', '[]'::jsonb)) = 0 then
    raise exception 'La salida no tiene mercancía.';
  end if;

  -- Prefijo: el escrito en la ficha del cliente o, si no hay, las 3 primeras letras de su nombre
  select upper(left(regexp_replace(coalesce(nullif(trim(sc.prefijo), ''), nullif(trim(c.nombre_comercial), ''), c.nombre, 'ALB'), '[^A-Za-z]', '', 'g'), 3))
    into v_pref
    from public.contactos c left join public.sga_clientes sc on sc.cliente_id = c.id
    where c.id = v_cli;
  if v_pref is null or length(v_pref) = 0 then v_pref := 'ALB'; end if;

  perform pg_advisory_xact_lock(hashtextextended(v_cli::text || v_fecha::text, 0));
  select count(*) + 1 into v_seq from public.sga_albaranes where cliente_id = v_cli and tipo = 'salida' and fecha = v_fecha and numero_texto is not null;

  insert into public.sga_albaranes (created_by, tipo, cliente_id, warehouse_id, fecha, referencia, modalidad, transportista, matricula, observaciones,
                                    estado, confirmado_at, numero_texto, destinatario, destinatario_direccion)
  values (a->>'created_by', 'salida', v_cli, a->>'warehouse_id', v_fecha,
          nullif(a->>'referencia', ''), coalesce(nullif(a->>'modalidad', ''), 'palet'),
          nullif(a->>'transportista', ''), nullif(a->>'matricula', ''), nullif(a->>'observaciones', ''), 'confirmado', now(),
          v_pref || to_char(v_fecha, 'DDMMYYYY') || '-' || v_seq, nullif(a->>'destinatario', ''), nullif(a->>'destinatario_direccion', ''))
  returning id into v_albaran;

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
          estado = case when cantidad_actual - v_cant = 0 then 'agotada' else estado end
      where id = (r->>'partida_id')::uuid;
    insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, fifo_saltado, bultos)
    values (a->>'created_by', (r->>'partida_id')::uuid, v_albaran, 'salida', -v_cant, v_fecha, coalesce((r->>'fifo_saltado')::boolean, false),
            case when v_bultos is null then null else -v_bultos end);
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

-- ---------- Regularizar stock ----------
-- p = { albaran:{cliente_id, warehouse_id, fecha, motivo, created_by}, items:[{partida_id, delta, bultos}] }
create or replace function public.sga_regularizar(p jsonb) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  a jsonb := p->'albaran';
  v_albaran uuid;
  v_fecha date := (a->>'fecha')::date;
  v_cli uuid := (a->>'cliente_id')::uuid;
  v_actual int;
  v_delta int;
  v_bultos numeric;
  r jsonb;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para regularizar stock.';
  end if;
  if jsonb_array_length(coalesce(p->'items', '[]'::jsonb)) = 0 then
    raise exception 'No hay nada que regularizar.';
  end if;
  if nullif(trim(a->>'motivo'), '') is null then
    raise exception 'Indica el motivo de la regularización.';
  end if;

  insert into public.sga_albaranes (created_by, tipo, cliente_id, warehouse_id, fecha, observaciones, estado, confirmado_at)
  values (a->>'created_by', 'regularizacion', v_cli, a->>'warehouse_id', v_fecha, a->>'motivo', 'confirmado', now())
  returning id into v_albaran;

  for r in select value from jsonb_array_elements(p->'items') loop
    v_delta := (r->>'delta')::int;
    v_bultos := nullif(r->>'bultos', '')::numeric;
    if v_delta = 0 then continue; end if;
    select cantidad_actual into v_actual from public.sga_partidas
      where id = (r->>'partida_id')::uuid and cliente_id = v_cli for update;
    if not found then
      raise exception 'Una de las partidas ya no existe o no es de este cliente. Recarga la pantalla.';
    end if;
    if v_actual + v_delta < 0 then
      raise exception 'La regularización dejaría una partida en negativo (hay %, se quitan %).', v_actual, -v_delta;
    end if;
    update public.sga_partidas
      set cantidad_actual = cantidad_actual + v_delta,
          estado = case when cantidad_actual + v_delta = 0 then 'agotada' else 'activa' end
      where id = (r->>'partida_id')::uuid;
    insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, bultos, nota)
    values (a->>'created_by', (r->>'partida_id')::uuid, v_albaran, 'ajuste', v_delta, v_fecha, v_bultos, a->>'motivo');
  end loop;

  return v_albaran;
end $$;

-- ---------- Anular un albarán (entrada, salida o stock inicial) ----------
create or replace function public.sga_anular_albaran(p_id uuid, p_motivo text, p_usuario text) returns void
language plpgsql security invoker set search_path = public as $$
declare
  a public.sga_albaranes%rowtype;
  pt public.sga_partidas%rowtype;
  mv record;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para anular albaranes.';
  end if;
  if nullif(trim(p_motivo), '') is null then
    raise exception 'Indica el motivo de la anulación.';
  end if;
  select * into a from public.sga_albaranes where id = p_id for update;
  if not found then raise exception 'El albarán no existe.'; end if;
  if a.estado <> 'confirmado' then raise exception 'Este albarán ya está anulado.'; end if;
  if a.tipo = 'regularizacion' then
    raise exception 'Una regularización no se anula: corrígela con otra regularización.';
  end if;

  if a.tipo in ('entrada', 'apertura') then
    -- La mercancía debe seguir intacta: si ya ha salido algo, hay que anular antes esas salidas.
    for pt in select * from public.sga_partidas where albaran_entrada_id = p_id for update loop
      if pt.cantidad_actual <> pt.cantidad_inicial then
        raise exception 'No se puede anular: parte de esta mercancía ya ha salido o se ha regularizado. Anula antes esas salidas.';
      end if;
      update public.sga_partidas set cantidad_actual = 0, estado = 'anulada' where id = pt.id;
      insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, bultos, nota)
      values (p_usuario, pt.id, p_id, 'ajuste', -pt.cantidad_inicial, a.fecha, case when pt.bultos is null then null else -pt.bultos end, 'Anulación del albarán');
    end loop;
  elsif a.tipo = 'salida' then
    for mv in select * from public.sga_movimientos where albaran_id = p_id and tipo = 'salida' loop
      select * into pt from public.sga_partidas where id = mv.partida_id for update;
      if pt.estado = 'anulada' then
        raise exception 'No se puede anular: la entrada de parte de esta mercancía está anulada.';
      end if;
      update public.sga_partidas set cantidad_actual = cantidad_actual - mv.cantidad, estado = 'activa' where id = pt.id;   -- mv.cantidad es negativa
      insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, bultos, nota)
      values (p_usuario, pt.id, p_id, 'ajuste', -mv.cantidad, a.fecha, case when mv.bultos is null then null else -mv.bultos end, 'Anulación del albarán');
    end loop;
  end if;

  update public.sga_albaranes set estado = 'anulado', anulado_at = now(), anulado_motivo = p_motivo where id = p_id;
  update public.sga_cobros set estado = 'anulado' where albaran_id = p_id;
end $$;

notify pgrst, 'reload schema';

-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Regularización con palets del catálogo (mercancía que no está en el stock)
-- Sustituye a las dos funciones de la regularización (misma firma, se puede ejecutar más de una vez):
--   sga_regularizar(p)                   crear una regularización
--   sga_editar_regularizacion(p_id, p)   editarla (misma pantalla; se deshace la original y se aplica la nueva, todo o nada)
-- Novedad: p puede llevar «nuevas», una lista de mercancía del catálogo que el cliente no tiene en ese almacén: cada una crea su PARTIDA
-- (con su tipo de carga, artículo y tipo de palet) y su movimiento de regularización (+ cantidad). No genera cobros (una regularización no cobra).
-- Al editar, una partida creada por la propia regularización sigue a su cantidad (y se retira si se deja en 0, siempre que no haya salido nada de ella).
-- No se permite dejar una partida en negativo, ni una regularización sin líneas, ni editar una anulada.
--
-- p = { albaran:{ cliente_id, warehouse_id, fecha, motivo, created_by },
--       items:[{ partida_id, delta, bultos }],                       -- partidas que ya existen (solo las que cambian)
--       nuevas:[{ producto_id, articulo_id, referencia, descripcion, cantidad, bultos, atributos }] }
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.sga_albaranes add column if not exists editado_at timestamptz;
alter table public.sga_albaranes add column if not exists editado_por text;

-- ---------- Crear una regularización ----------
create or replace function public.sga_regularizar(p jsonb) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  a jsonb := p->'albaran';
  v_albaran uuid;
  v_fecha date := (a->>'fecha')::date;
  v_cli uuid := (a->>'cliente_id')::uuid;
  v_actual int;
  v_delta int;
  v_cant int;
  v_bultos numeric;
  v_pid uuid;
  r jsonb;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para regularizar stock.';
  end if;
  if jsonb_array_length(coalesce(p->'items', '[]'::jsonb)) = 0 and jsonb_array_length(coalesce(p->'nuevas', '[]'::jsonb)) = 0 then
    raise exception 'No hay nada que regularizar.';
  end if;
  if nullif(trim(a->>'motivo'), '') is null then
    raise exception 'Indica el motivo de la regularización.';
  end if;

  insert into public.sga_albaranes (created_by, tipo, cliente_id, warehouse_id, fecha, observaciones, estado, confirmado_at)
  values (a->>'created_by', 'regularizacion', v_cli, a->>'warehouse_id', v_fecha, a->>'motivo', 'confirmado', now())
  returning id into v_albaran;

  for r in select value from jsonb_array_elements(coalesce(p->'items', '[]'::jsonb)) loop
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

  -- Mercancía del catálogo que no estaba en el stock: nace su partida
  for r in select value from jsonb_array_elements(coalesce(p->'nuevas', '[]'::jsonb)) loop
    v_cant := (r->>'cantidad')::int;
    if v_cant is null or v_cant < 1 then raise exception 'La cantidad de cada línea nueva tiene que ser 1 o más.'; end if;
    v_bultos := nullif(r->>'bultos', '')::numeric;
    insert into public.sga_partidas (cliente_id, warehouse_id, producto_id, referencia, descripcion, cantidad_inicial, cantidad_actual, fecha_entrada, albaran_entrada_id, atributos, articulo_id, bultos)
    values (v_cli, a->>'warehouse_id', nullif(r->>'producto_id', ''), nullif(r->>'referencia', ''), nullif(r->>'descripcion', ''), v_cant, v_cant, v_fecha, v_albaran,
            coalesce(r->'atributos', '{}'::jsonb), nullif(r->>'articulo_id', '')::uuid, v_bultos)
    returning id into v_pid;
    insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, bultos, nota)
    values (a->>'created_by', v_pid, v_albaran, 'ajuste', v_cant, v_fecha, v_bultos, a->>'motivo');
  end loop;

  return v_albaran;
end $$;

-- ---------- Editar una regularización ----------
create or replace function public.sga_editar_regularizacion(p_id uuid, p jsonb) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  a jsonb := p->'albaran';
  alb public.sga_albaranes%rowtype;
  v_fecha date := (a->>'fecha')::date;
  v_motivo text := nullif(trim(a->>'motivo'), '');
  v_cli uuid;
  v_pid uuid;
  v_alb uuid;
  v_actual int;
  v_old int;
  v_new int;
  v_nuevo int;
  v_delta int;
  v_cant int;
  v_otros int;
  v_bultos numeric;
  v_borrar uuid[] := '{}';
  v_np uuid;
  r jsonb;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para editar regularizaciones.';
  end if;
  select * into alb from public.sga_albaranes where id = p_id for update;
  if not found then raise exception 'El albarán no existe.'; end if;
  if alb.tipo <> 'regularizacion' then raise exception 'Solo se pueden editar regularizaciones.'; end if;
  if alb.estado <> 'confirmado' then raise exception 'Esta regularización está anulada: no se puede editar.'; end if;
  if v_motivo is null then raise exception 'Indica el motivo de la regularización.'; end if;
  v_cli := alb.cliente_id;
  if jsonb_array_length(coalesce(p->'items', '[]'::jsonb)) = 0 and jsonb_array_length(coalesce(p->'nuevas', '[]'::jsonb)) = 0 then
    raise exception 'La regularización no puede quedarse sin ninguna línea.';
  end if;

  -- 1) Partidas afectadas (las de la regularización original y las de la nueva): se recalcula su cantidad
  for v_pid in
    select x from (
      select partida_id as x from public.sga_movimientos where albaran_id = p_id and tipo = 'ajuste'
      union
      select (e->>'partida_id')::uuid from jsonb_array_elements(coalesce(p->'items', '[]'::jsonb)) e
    ) t
  loop
    select cantidad_actual, albaran_entrada_id into v_actual, v_alb from public.sga_partidas where id = v_pid and cliente_id = v_cli for update;
    if not found then
      raise exception 'Una de las partidas ya no existe o no es de este cliente. Recarga la pantalla.';
    end if;
    select coalesce(sum(cantidad), 0) into v_old from public.sga_movimientos where albaran_id = p_id and tipo = 'ajuste' and partida_id = v_pid;
    select coalesce(sum((e->>'delta')::int), 0) into v_new from jsonb_array_elements(coalesce(p->'items', '[]'::jsonb)) e where (e->>'partida_id')::uuid = v_pid;
    v_nuevo := v_actual - v_old + v_new;          -- se deshace la regularización original y se aplica la nueva
    if v_nuevo < 0 then
      raise exception 'La edición dejaría una partida en negativo (hay %, la regularización original sumaba %).', v_actual, v_old;
    end if;
    if v_alb is not distinct from p_id then
      -- partida creada por esta misma regularización: su cantidad inicial la sigue; si se deja en 0 se retira (solo si no ha salido nada de ella)
      select count(*) into v_otros from public.sga_movimientos where partida_id = v_pid and albaran_id is distinct from p_id;
      if v_new <= 0 then
        if v_new < 0 then raise exception 'Una partida creada por esta regularización no puede quedar en negativo.'; end if;
        if v_otros > 0 then raise exception 'No se puede quitar de la regularización una partida de la que ya ha salido mercancía.'; end if;
        v_borrar := array_append(v_borrar, v_pid);
      else
        update public.sga_partidas set cantidad_inicial = cantidad_inicial - v_old + v_new where id = v_pid;
      end if;
    end if;
    update public.sga_partidas
      set cantidad_actual = v_nuevo,
          estado = case when v_nuevo = 0 then 'agotada' else 'activa' end
      where id = v_pid;
  end loop;

  -- 2) Las líneas (movimientos) se rehacen con lo nuevo
  delete from public.sga_movimientos where albaran_id = p_id and tipo = 'ajuste';
  if array_length(v_borrar, 1) is not null then
    delete from public.sga_partidas where id = any(v_borrar);
  end if;
  for r in select value from jsonb_array_elements(coalesce(p->'items', '[]'::jsonb)) loop
    v_delta := (r->>'delta')::int;
    if v_delta = 0 then continue; end if;
    insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, bultos, nota)
    values (a->>'created_by', (r->>'partida_id')::uuid, p_id, 'ajuste', v_delta, v_fecha, nullif(r->>'bultos', '')::numeric, v_motivo);
  end loop;

  -- 3) Mercancía del catálogo que no estaba en el stock: nace su partida
  for r in select value from jsonb_array_elements(coalesce(p->'nuevas', '[]'::jsonb)) loop
    v_cant := (r->>'cantidad')::int;
    if v_cant is null or v_cant < 1 then raise exception 'La cantidad de cada línea nueva tiene que ser 1 o más.'; end if;
    v_bultos := nullif(r->>'bultos', '')::numeric;
    insert into public.sga_partidas (cliente_id, warehouse_id, producto_id, referencia, descripcion, cantidad_inicial, cantidad_actual, fecha_entrada, albaran_entrada_id, atributos, articulo_id, bultos)
    values (v_cli, alb.warehouse_id, nullif(r->>'producto_id', ''), nullif(r->>'referencia', ''), nullif(r->>'descripcion', ''), v_cant, v_cant, v_fecha, p_id,
            coalesce(r->'atributos', '{}'::jsonb), nullif(r->>'articulo_id', '')::uuid, v_bultos)
    returning id into v_np;
    insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, bultos, nota)
    values (a->>'created_by', v_np, p_id, 'ajuste', v_cant, v_fecha, v_bultos, v_motivo);
  end loop;

  if not exists (select 1 from public.sga_movimientos where albaran_id = p_id) then
    raise exception 'La regularización no puede quedarse sin ninguna línea.';
  end if;

  -- 4) Datos del albarán
  update public.sga_albaranes
    set fecha = v_fecha, observaciones = v_motivo, editado_at = now(), editado_por = a->>'created_by'
    where id = p_id;
  return p_id;
end $$;

notify pgrst, 'reload schema';

-- Comprobación: deben salir 2 filas
select proname from pg_proc where proname in ('sga_regularizar', 'sga_editar_regularizacion') order by 1;

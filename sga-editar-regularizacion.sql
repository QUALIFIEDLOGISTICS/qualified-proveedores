-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Editar una regularización de inventario (misma pantalla que al crearla)
-- En UNA sola operación (todo o nada):
--   · Se DESHACE la regularización original (lo que sumó o quitó a cada partida) y se APLICA la nueva.
--   · Las líneas de la regularización se rehacen con lo que llegue: se pueden cambiar cantidades, quitar líneas (diferencia 0) o añadir partidas nuevas.
--   · Se pueden cambiar la fecha y el motivo. El cliente y el almacén no cambian.
--   · No se permite dejar una partida en negativo, ni una regularización sin líneas, ni editar una anulada.
-- El albarán conserva su número. No toca cobros (una regularización no cobra nada).
-- Sustituye a la versión anterior de esta función (misma firma): se puede ejecutar más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.sga_albaranes add column if not exists editado_at timestamptz;
alter table public.sga_albaranes add column if not exists editado_por text;

-- p = { albaran:{ fecha, motivo, created_by }, items:[{ partida_id, delta, bultos }] }   (solo las partidas con diferencia distinta de 0)
create or replace function public.sga_editar_regularizacion(p_id uuid, p jsonb) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  a jsonb := p->'albaran';
  alb public.sga_albaranes%rowtype;
  v_fecha date := (a->>'fecha')::date;
  v_motivo text := nullif(trim(a->>'motivo'), '');
  v_cli uuid;
  v_pid uuid;
  v_actual int;
  v_old int;
  v_new int;
  v_nuevo int;
  v_delta int;
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
  if jsonb_array_length(coalesce(p->'items', '[]'::jsonb)) = 0 then
    raise exception 'La regularización no puede quedarse sin ninguna línea.';
  end if;

  -- 1) Partidas afectadas (las de la regularización original y las de la nueva): se recalcula su cantidad
  for v_pid in
    select x from (
      select partida_id as x from public.sga_movimientos where albaran_id = p_id and tipo = 'ajuste'
      union
      select (e->>'partida_id')::uuid from jsonb_array_elements(p->'items') e
    ) t
  loop
    select cantidad_actual into v_actual from public.sga_partidas where id = v_pid and cliente_id = v_cli for update;
    if not found then
      raise exception 'Una de las partidas ya no existe o no es de este cliente. Recarga la pantalla.';
    end if;
    select coalesce(sum(cantidad), 0) into v_old from public.sga_movimientos where albaran_id = p_id and tipo = 'ajuste' and partida_id = v_pid;
    select coalesce(sum((e->>'delta')::int), 0) into v_new from jsonb_array_elements(p->'items') e where (e->>'partida_id')::uuid = v_pid;
    v_nuevo := v_actual - v_old + v_new;          -- se deshace la regularización original y se aplica la nueva
    if v_nuevo < 0 then
      raise exception 'La edición dejaría una partida en negativo (hay %, la regularización original sumaba %).', v_actual, v_old;
    end if;
    update public.sga_partidas
      set cantidad_actual = v_nuevo,
          estado = case when v_nuevo = 0 then 'agotada' else 'activa' end
      where id = v_pid;
  end loop;

  -- 2) Las líneas (movimientos) se rehacen con lo nuevo
  delete from public.sga_movimientos where albaran_id = p_id and tipo = 'ajuste';
  for r in select value from jsonb_array_elements(p->'items') loop
    v_delta := (r->>'delta')::int;
    if v_delta = 0 then continue; end if;
    insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, bultos, nota)
    values (a->>'created_by', (r->>'partida_id')::uuid, p_id, 'ajuste', v_delta, v_fecha, nullif(r->>'bultos', '')::numeric, v_motivo);
  end loop;

  -- 3) Datos del albarán
  update public.sga_albaranes
    set fecha = v_fecha, observaciones = v_motivo, editado_at = now(), editado_por = a->>'created_by'
    where id = p_id;
  return p_id;
end $$;

notify pgrst, 'reload schema';

-- Comprobación: debe salir 1 fila
select proname from pg_proc where proname = 'sga_editar_regularizacion';

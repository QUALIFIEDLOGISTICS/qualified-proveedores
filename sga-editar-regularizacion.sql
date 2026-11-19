-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Editar una regularización de inventario
-- En UNA sola operación (todo o nada):
--   · Cada línea de la regularización puede cambiar su diferencia (+ suma palets, − quita). El stock de la partida se recalcula:
--     se deshace lo que hizo la regularización original y se aplica lo nuevo.
--   · Una línea que se deja en 0 se quita de la regularización (y la partida vuelve a como estaba antes de ella).
--   · Se puede cambiar la fecha y el motivo.
--   · No se permite dejar una partida en negativo, ni editar una regularización anulada.
-- El albarán conserva su número. No toca cobros (una regularización no cobra nada).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================

alter table public.sga_albaranes add column if not exists editado_at timestamptz;
alter table public.sga_albaranes add column if not exists editado_por text;

-- p = { albaran:{ fecha, motivo, created_by }, items:[{ movimiento_id, delta }] }
create or replace function public.sga_editar_regularizacion(p_id uuid, p jsonb) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  a jsonb := p->'albaran';
  alb public.sga_albaranes%rowtype;
  mv public.sga_movimientos%rowtype;
  v_fecha date := (a->>'fecha')::date;
  v_motivo text := nullif(trim(a->>'motivo'), '');
  v_actual int;
  v_nuevo int;
  v_delta int;
  v_bultos numeric;
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

  for r in select value from jsonb_array_elements(coalesce(p->'items', '[]'::jsonb)) loop
    v_delta := (r->>'delta')::int;
    select * into mv from public.sga_movimientos
      where id = (r->>'movimiento_id')::uuid and albaran_id = p_id and tipo = 'ajuste' for update;
    if not found then raise exception 'Una de las líneas ya no existe. Recarga la pantalla.'; end if;

    select cantidad_actual into v_actual from public.sga_partidas where id = mv.partida_id for update;
    v_nuevo := v_actual - mv.cantidad + v_delta;      -- se deshace la regularización original y se aplica la nueva
    if v_nuevo < 0 then
      raise exception 'La edición dejaría una partida en negativo (hay %, la regularización original sumaba %).', v_actual, mv.cantidad;
    end if;
    update public.sga_partidas
      set cantidad_actual = v_nuevo,
          estado = case when v_nuevo = 0 then 'agotada' else 'activa' end
      where id = mv.partida_id;

    if v_delta = 0 then
      delete from public.sga_movimientos where id = mv.id;
    else
      -- los bultos se reparten en la misma proporción que la cantidad
      v_bultos := case when mv.bultos is not null and mv.cantidad <> 0 then round(mv.bultos * v_delta / mv.cantidad, 2) else null end;
      update public.sga_movimientos set cantidad = v_delta, fecha = v_fecha, nota = v_motivo, bultos = coalesce(v_bultos, bultos) where id = mv.id;
    end if;
  end loop;

  if not exists (select 1 from public.sga_movimientos where albaran_id = p_id) then
    raise exception 'La regularización no puede quedarse sin ninguna línea.';
  end if;

  update public.sga_movimientos set fecha = v_fecha, nota = v_motivo where albaran_id = p_id;
  update public.sga_albaranes
    set fecha = v_fecha, observaciones = v_motivo, editado_at = now(), editado_por = a->>'created_by'
    where id = p_id;
  return p_id;
end $$;

notify pgrst, 'reload schema';

-- Comprobación: debe salir 1 fila
select proname from pg_proc where proname = 'sga_editar_regularizacion';

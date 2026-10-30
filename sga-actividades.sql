-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Actividades
-- Trabajos que se hacen para un cliente y no son ni recepción ni expedición (verificación de inventario, recuentos, etiquetado…)
-- y que hay que cobrar. Se guardan como un albarán numerado de tipo «actividad», sin mover stock, con sus servicios y sus cobros
-- (entran en la liquidación del mes como el resto de servicios). Se pueden anular como cualquier albarán.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar las veces que haga falta.
-- ============================================================

-- El tipo de albarán admite también «actividad»
alter table public.sga_albaranes drop constraint if exists sga_albaranes_tipo_check;
alter table public.sga_albaranes add constraint sga_albaranes_tipo_check check (tipo in ('entrada', 'salida', 'apertura', 'regularizacion', 'actividad'));

-- p = { albaran:{cliente_id, warehouse_id, fecha, referencia, observaciones, created_by},
--       servicios:[{producto_id, cantidad, nota}], cobros:[{origen, producto_id, subtipo, cantidad, precio, importe, tarifa_id, nota}] }
create or replace function public.sga_confirmar_actividad(p jsonb) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  a jsonb := p->'albaran';
  v_albaran uuid;
  v_fecha date := (a->>'fecha')::date;
  v_cli uuid := (a->>'cliente_id')::uuid;
  r jsonb;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para registrar actividades.';
  end if;
  if jsonb_array_length(coalesce(p->'servicios', '[]'::jsonb)) = 0 then
    raise exception 'La actividad no tiene ningún servicio.';
  end if;

  insert into public.sga_albaranes (created_by, tipo, cliente_id, warehouse_id, fecha, referencia, modalidad, observaciones, estado, confirmado_at)
  values (a->>'created_by', 'actividad', v_cli, a->>'warehouse_id', v_fecha, nullif(a->>'referencia', ''), 'palet', nullif(a->>'observaciones', ''), 'confirmado', now())
  returning id into v_albaran;

  for r in select value from jsonb_array_elements(p->'servicios') loop
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

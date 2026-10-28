-- ============================================================
-- QUALIFIED PROVEEDORES — Franja horaria reservada desde una orden de carga (Transporte)
-- En la orden de carga se puede reservar la franja de un almacén eligiendo almacén, cliente, día y hora.
-- Queda como cita con hora en Franjas horarias, enlazada a la orden (sin adjuntar ningún PDF).
-- Si se anula la orden o se desmarca la franja, se quita. Usa los permisos de Transporte, así que no hace falta
-- acceso a Franjas horarias para reservarla desde la orden. Comprueba que no haya ya 2 camiones a esa hora.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
alter table public.appointments add column if not exists orden_carga_id uuid references public.ordenes_carga(id) on delete set null;
alter table public.unscheduled_trucks add column if not exists orden_carga_id uuid references public.ordenes_carga(id) on delete set null;
create index if not exists appointments_orden_idx on public.appointments (orden_carga_id);
create index if not exists unscheduled_trucks_orden_idx on public.unscheduled_trucks (orden_carga_id);

-- Crea o actualiza la cita de una orden de carga. Devuelve {accion: 'creada'|'actualizada'}
create or replace function public.oc_franja(p jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_orden uuid := (p->>'orden_id')::uuid;
  v_wh text := p->>'warehouse_id';
  v_cli uuid := (p->>'client_id')::uuid;
  v_fecha date := (p->>'date')::date;
  v_start text := p->>'start_time';
  v_dur int := coalesce((p->>'duration_min')::int, 60);
  v_tipo text := coalesce(nullif(p->>'type', ''), 'carga');
  v_carrier text := nullif(p->>'carrier', '');
  v_plate text := nullif(p->>'plate', '');
  v_trailer text := nullif(p->>'trailer_plate', '');
  v_ref text := nullif(p->>'cargo_ref', '');
  v_cita_id uuid;
  v_av_id uuid;
  v_n int;
  v_id uuid;
begin
  if not public.sga_permiso('trafico') then
    raise exception 'No tienes permiso para reservar franjas desde las órdenes de carga.';
  end if;
  if v_start is null or v_start !~ '^\d{2}:\d{2}$' then
    raise exception 'La hora de la franja no es válida.';
  end if;

  -- cupo: como mucho 2 camiones a la vez en un almacén (sin contar la propia cita de esta orden)
  select count(*) into v_n from public.appointments a
   where a.warehouse_id = v_wh and a.date = v_fecha and a.orden_carga_id is distinct from v_orden
     and a.start_time::time < (v_start::time + make_interval(mins => v_dur))
     and (a.start_time::time + make_interval(mins => a.duration_min)) > v_start::time;
  if v_n >= 2 then
    raise exception 'Ya hay 2 camiones reservados en ese horario. Elige otra franja.';
  end if;

  select id into v_cita_id from public.appointments where orden_carga_id = v_orden limit 1;
  if v_cita_id is not null then
    update public.appointments set warehouse_id = v_wh, client_id = v_cli, date = v_fecha, start_time = v_start, duration_min = v_dur,
      type = v_tipo, carrier = coalesce(v_carrier, carrier), plate = coalesce(v_plate, plate),
      trailer_plate = coalesce(v_trailer, trailer_plate), cargo_ref = coalesce(v_ref, cargo_ref)
    where id = v_cita_id;
    return jsonb_build_object('accion', 'actualizada');
  end if;

  select id into v_av_id from public.unscheduled_trucks where orden_carga_id = v_orden limit 1;
  insert into public.appointments (warehouse_id, client_id, date, start_time, duration_min, status, carrier, plate, trailer_plate, cargo_ref, type, orden_carga_id)
  values (v_wh, v_cli, v_fecha, v_start, v_dur, 'planificado', v_carrier, v_plate, v_trailer, v_ref, v_tipo, v_orden)
  returning id into v_id;
  if v_av_id is not null then   -- si estaba como camión sin cita, la cita lo sustituye y se queda con sus documentos
    update public.attachments set parent_type = 'appointment', parent_id = v_id where parent_type = 'unscheduled' and parent_id = v_av_id;
    delete from public.unscheduled_trucks where id = v_av_id;
  end if;
  return jsonb_build_object('accion', 'creada');
end $$;

-- Quita la franja de una orden de carga (cita o aviso), salvo que ya esté marcada como completada
create or replace function public.oc_franja_quitar(p_orden uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_a uuid[];
  v_u uuid[];
begin
  if not public.sga_permiso('trafico') then
    raise exception 'No tienes permiso para quitar franjas desde las órdenes de carga.';
  end if;
  select coalesce(array_agg(id), '{}') into v_a from public.appointments where orden_carga_id = p_orden and status <> 'completado';
  select coalesce(array_agg(id), '{}') into v_u from public.unscheduled_trucks where orden_carga_id = p_orden and status <> 'completado';
  delete from public.attachments where parent_type = 'appointment' and parent_id = any(v_a);
  delete from public.attachments where parent_type = 'unscheduled' and parent_id = any(v_u);
  delete from public.appointments where id = any(v_a);
  delete from public.unscheduled_trucks where id = any(v_u);
  return jsonb_build_object('citas', coalesce(array_length(v_a, 1), 0), 'avisos', coalesce(array_length(v_u, 1), 0));
end $$;

grant execute on function public.oc_franja(jsonb) to authenticated;
grant execute on function public.oc_franja_quitar(uuid) to authenticated;
notify pgrst, 'reload schema';

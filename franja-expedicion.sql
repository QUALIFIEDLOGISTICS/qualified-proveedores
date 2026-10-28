-- ============================================================
-- QUALIFIED PROVEEDORES — Franja horaria vinculada a una expedición de Almacén (SGA)
-- Al guardar una expedición (borrador o confirmada) se apunta un «camión sin cita» ese día en Franjas horarias.
-- Si le pones hora, pasa a cita y sigue vinculada. Si cambia la fecha de salida, se mueve de día (aviso o cita).
-- Si se anula la expedición, se quita. Las funciones usan los permisos de Control Stock SGA, así que no hace falta
-- tener acceso a Franjas horarias para que la reserva se cree sola.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
alter table public.unscheduled_trucks add column if not exists albaran_id uuid references public.sga_albaranes(id) on delete set null;
alter table public.appointments add column if not exists albaran_id uuid references public.sga_albaranes(id) on delete set null;
create index if not exists unscheduled_trucks_albaran_idx on public.unscheduled_trucks (albaran_id);
create index if not exists appointments_albaran_idx on public.appointments (albaran_id);

-- Crea o actualiza la franja de una expedición. Devuelve {accion: 'creada'|'actualizada', cita: true|false, hora, fecha_antes}
create or replace function public.sga_franja_expedicion(p jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_alb uuid := (p->>'albaran_id')::uuid;
  v_wh text := p->>'warehouse_id';
  v_cli uuid := (p->>'client_id')::uuid;
  v_fecha date := (p->>'date')::date;
  v_carrier text := nullif(p->>'carrier', '');
  v_plate text := nullif(p->>'plate', '');
  v_trailer text := nullif(p->>'trailer_plate', '');
  v_ref text := nullif(p->>'cargo_ref', '');
  v_cita public.appointments%rowtype;
  v_av public.unscheduled_trucks%rowtype;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para reservar franjas desde las expediciones.';
  end if;

  -- ya tiene hora: se mueve de día (la hora se conserva)
  select * into v_cita from public.appointments where albaran_id = v_alb limit 1;
  if found then
    update public.appointments set warehouse_id = v_wh, client_id = v_cli, date = v_fecha,
      carrier = coalesce(v_carrier, carrier), plate = coalesce(v_plate, plate),
      trailer_plate = coalesce(v_trailer, trailer_plate), cargo_ref = coalesce(v_ref, cargo_ref)
    where id = v_cita.id;
    return jsonb_build_object('accion', 'actualizada', 'cita', true, 'hora', v_cita.start_time, 'fecha_antes', v_cita.date);
  end if;

  -- aviso sin hora
  select * into v_av from public.unscheduled_trucks where albaran_id = v_alb limit 1;
  if found then
    update public.unscheduled_trucks set warehouse_id = v_wh, client_id = v_cli, date = v_fecha,
      carrier = coalesce(v_carrier, carrier), plate = coalesce(v_plate, plate),
      trailer_plate = coalesce(v_trailer, trailer_plate), cargo_ref = coalesce(v_ref, cargo_ref)
    where id = v_av.id;
    return jsonb_build_object('accion', 'actualizada', 'cita', false, 'fecha_antes', v_av.date);
  end if;

  insert into public.unscheduled_trucks (warehouse_id, client_id, date, status, carrier, plate, trailer_plate, cargo_ref, type, notes, albaran_id)
  values (v_wh, v_cli, v_fecha, 'planificado', v_carrier, v_plate, v_trailer, v_ref, 'carga', nullif(p->>'notes', ''), v_alb);
  return jsonb_build_object('accion', 'creada', 'cita', false);
end $$;

-- Quita la franja de una expedición (aviso o cita), salvo que ya esté marcada como completada
create or replace function public.sga_franja_expedicion_quitar(p_albaran uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_a uuid[];
  v_u uuid[];
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para quitar franjas desde las expediciones.';
  end if;
  select coalesce(array_agg(id), '{}') into v_a from public.appointments where albaran_id = p_albaran and status <> 'completado';
  select coalesce(array_agg(id), '{}') into v_u from public.unscheduled_trucks where albaran_id = p_albaran and status <> 'completado';
  delete from public.attachments where parent_type = 'appointment' and parent_id = any(v_a);
  delete from public.attachments where parent_type = 'unscheduled' and parent_id = any(v_u);
  delete from public.appointments where id = any(v_a);
  delete from public.unscheduled_trucks where id = any(v_u);
  return jsonb_build_object('citas', coalesce(array_length(v_a, 1), 0), 'avisos', coalesce(array_length(v_u, 1), 0));
end $$;

grant execute on function public.sga_franja_expedicion(jsonb) to authenticated;
grant execute on function public.sga_franja_expedicion_quitar(uuid) to authenticated;
notify pgrst, 'reload schema';

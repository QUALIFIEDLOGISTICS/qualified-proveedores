-- ============================================================
-- QUALIFIED PROVEEDORES — Albarán en PDF adjunto a la franja horaria de una expedición
-- Al reservar la franja desde la expedición, el PDF del albarán queda adjunto a la franja (aviso sin hora o cita).
-- Si la expedición se vuelve a guardar, el adjunto se sustituye por el PDF actualizado.
-- Usa los permisos de Control Stock SGA, así que no hace falta acceso a Franjas horarias.
-- Requiere haber ejecutado antes franja-expedicion.sql.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
create or replace function public.sga_franja_adjuntar(p_albaran uuid, p_name text, p_path text, p_size int) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_tipo text;
  v_id uuid;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para adjuntar documentos a la franja de una expedición.';
  end if;

  select id into v_id from public.appointments where albaran_id = p_albaran limit 1;
  if found then
    v_tipo := 'appointment';
  else
    select id into v_id from public.unscheduled_trucks where albaran_id = p_albaran limit 1;
    if not found then
      return jsonb_build_object('adjuntado', false);
    end if;
    v_tipo := 'unscheduled';
  end if;

  delete from public.attachments where parent_type = v_tipo and parent_id = v_id and storage_path = p_path;
  insert into public.attachments (parent_type, parent_id, name, storage_path, size)
  values (v_tipo, v_id, p_name, p_path, p_size);
  return jsonb_build_object('adjuntado', true);
end $$;

grant execute on function public.sga_franja_adjuntar(uuid, text, text, int) to authenticated;
notify pgrst, 'reload schema';

-- ============================================================
-- QUALIFIED PROVEEDORES — Un cliente con movimientos o que ha tenido stock NO se puede eliminar nunca
-- Aunque alguien lo intente por otro camino, la base de datos lo impide: solo se pueden archivar.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
create or replace function public.contactos_no_borrar_con_historial() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.sga_albaranes where cliente_id = old.id)
     or exists (select 1 from public.sga_partidas where cliente_id = old.id)
     or exists (select 1 from public.sga_cobros where cliente_id = old.id)
     or exists (select 1 from public.sga_operativas_realizadas where cliente_id = old.id) then
    raise exception 'Este cliente tiene movimientos o ha tenido stock: no se puede eliminar nunca, solo archivar.';
  end if;
  return old;
end $$;

drop trigger if exists contactos_no_borrar_con_historial on public.contactos;
create trigger contactos_no_borrar_con_historial before delete on public.contactos
  for each row execute function public.contactos_no_borrar_con_historial();

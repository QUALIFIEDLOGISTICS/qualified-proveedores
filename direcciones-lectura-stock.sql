-- ============================================================
-- QUALIFIED PROVEEDORES — En las salidas del SGA el destinatario se elige de la agenda
-- de Direcciones (Transporte → Direcciones), así que quien tenga Control Stock SGA
-- necesita poder LEER las direcciones. Solo cambia la lectura: crear, editar y borrar
-- sigue igual (administradores y pestaña Administración).
-- Instrucciones: Supabase → SQL Editor → pega esto → Run. Se puede ejecutar más de una vez.
-- ============================================================

drop policy if exists direcciones_select on public.direcciones;
create policy direcciones_select on public.direcciones for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion','trafico','stock']))
);

-- =====================================================================
-- Órdenes de carga · permitir eliminar las que están ANULADAS.
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
-- Solo se pueden borrar órdenes en estado «anulada»; las emitidas no.
-- =====================================================================

drop policy if exists ordenes_carga_delete on public.ordenes_carga;
create policy ordenes_carga_delete on public.ordenes_carga for delete using (
  estado = 'anulada'
  and exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);

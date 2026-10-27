-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Eliminar artículos del catálogo
-- Permite borrar un artículo de «Editar catálogo». Solo se puede si NO tiene entradas ni salidas: la propia base de datos lo impide
-- (sga_partidas.articulo_id apunta al artículo, así que un artículo con alguna partida, aunque esté agotada, no se borra).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
drop policy if exists sga_articulos_delete on public.sga_articulos;
create policy sga_articulos_delete on public.sga_articulos for delete using (public.sga_permiso('stock', 'almacenconfig'));
notify pgrst, 'reload schema';

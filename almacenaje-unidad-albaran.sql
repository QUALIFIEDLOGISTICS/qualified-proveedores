-- ============================================================
-- QUALIFIED PROVEEDORES — Almacén → Productos: unidad "Por albarán"
-- Sustituye la antigua unidad "Por contenedor" por "Por albarán"
-- (precio fijo por albarán, sea de contenedor o de otro tipo).
-- Las tarifas ya creadas no se tocan: van enlazadas al producto.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================
update public.almacenaje_productos set unidad = 'albaran' where unidad = 'contenedor';
notify pgrst, 'reload schema';

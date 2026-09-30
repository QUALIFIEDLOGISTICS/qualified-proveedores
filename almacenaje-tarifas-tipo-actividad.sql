-- ============================================================
-- QUALIFIED PROVEEDORES — Tarifa de almacenaje: se separa "qué es
-- exactamente" (Palet, M², Entrada, Hora operario...) de "a qué categoría
-- pertenece" (Almacenaje / Movimiento / Extra), para poder agrupar bien en
-- estadísticas futuras. La categoría se calcula sola según el tipo (no la
-- elige el usuario) y se guarda en la fila, para que no cambie sola con
-- el tiempo si el día de mañana se reclasifica algún tipo nuevo.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.almacenaje_tarifas add column if not exists tipo_actividad text;

update public.almacenaje_tarifas set tipo_actividad = case
  when tipo in ('palet', 'm2', 'bobina') then 'almacenaje'
  when tipo in ('entrada', 'salida') then 'movimiento'
  else 'extra'
end
where tipo_actividad is null;

alter table public.almacenaje_tarifas alter column tipo_actividad set not null;

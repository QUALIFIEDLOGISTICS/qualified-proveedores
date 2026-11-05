-- TOP CABLE S.A -TR: 3 líneas de tarifa (Carga Trailer Paletizado, Entrada Bobina, Salida Bobina) estaban guardadas como «Almacenaje»
-- aunque su producto es de «Movimiento». Esto las alinea con la categoría de su producto. Solo cambia dónde se ven; no toca precios.
-- Solo actualiza las líneas que no coinciden; debe devolver 3 filas.
update public.almacenaje_tarifas t
set tipo_actividad = p.categoria
from public.almacenaje_productos p
where p.id = t.tipo
  and t.tipo_actividad <> p.categoria
returning t.cliente_id, t.tipo, t.tipo_actividad;

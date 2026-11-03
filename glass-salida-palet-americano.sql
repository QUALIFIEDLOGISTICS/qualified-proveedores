-- GLASS FACTORY: la tarifa «Salida Palet» (1,50) pasa a ser «Salida Palet Americano».
-- Mismo precio y misma fecha; solo cambia el producto. Si no hay un único producto con ese nombre, falla y no toca nada.
update public.almacenaje_tarifas
set tipo = (select id from public.almacenaje_productos where nombre = 'Salida Palet Americano')
where id = '9243d06f-d1f1-45f5-943a-e94b70ededcd'
returning id, tipo, precio;

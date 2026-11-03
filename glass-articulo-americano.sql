-- GLASS FACTORY: el artículo del catálogo con «Tipo de palet» = Normal pasa a ser Americano
-- (su tarifa ya cobra «Entrada/Salida Palet Americano»). Solo toca a GLASS; debe devolver una fila.
update public.sga_articulos a
set atributos = jsonb_set(a.atributos, '{subtipo}', '"Americano"')
from public.contactos c
where c.id = a.cliente_id
  and c.nombre ilike '%glass%'
  and a.atributos->>'subtipo' = 'Normal'
returning a.nombre, a.referencia, a.atributos->>'subtipo' as tipo_de_palet;

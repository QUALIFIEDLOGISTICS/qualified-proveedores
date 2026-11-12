-- ============================================================
-- QUALIFIED PROVEEDORES — Diagnóstico (solo LEE, no cambia nada): comparar varios albaranes (cabecera, movimientos, cobros e historial)
-- Sirve para ver por qué uno se comporta distinto a otros: fechas distintas entre el albarán y sus movimientos, bultos que no cuadran, cobros con otra fecha…
-- Instrucciones: Supabase → SQL Editor. Cambia los números de albarán de la lista y pulsa Run. Ejecuta cada bloque por separado.
-- ============================================================

-- BLOQUE 1: cabecera de cada albarán
select a.numero_texto as albaran, a.fecha, a.tipo, a.estado, a.borrador, w.name as almacen, a.created_at, a.editado_at, a.editado_por, a.confirmado_at
from public.sga_albaranes a left join public.warehouses w on w.id = a.warehouse_id
where a.numero_texto in ('GLO13112026-1', 'GLO13112026-2', 'GLO13112026-3')
order by a.numero_texto;

-- BLOQUE 2: sus movimientos (¿la fecha del movimiento es la del albarán? ¿los bultos cuadran con los palets?)
select a.numero_texto as albaran, a.fecha as fecha_albaran, m.fecha as fecha_movimiento, m.tipo, m.cantidad as palets, m.bultos, p.descripcion as articulo, p.bultos as bultos_de_la_partida, p.cantidad_inicial, p.cantidad_actual
from public.sga_albaranes a
join public.sga_movimientos m on m.albaran_id = a.id
join public.sga_partidas p on p.id = m.partida_id
where a.numero_texto in ('GLO13112026-1', 'GLO13112026-2', 'GLO13112026-3')
order by a.numero_texto, p.descripcion;

-- BLOQUE 3: sus cobros
select a.numero_texto as albaran, c.fecha as fecha_cobro, c.periodo, c.origen, c.producto_id, c.cantidad, c.precio, c.importe, c.estado
from public.sga_albaranes a
join public.sga_cobros c on c.albaran_id = a.id
where a.numero_texto in ('GLO13112026-1', 'GLO13112026-2', 'GLO13112026-3')
order by a.numero_texto, c.origen;

-- BLOQUE 4: su historial
select a.numero_texto as albaran, h.created_at, h.usuario, h.resumen
from public.sga_albaranes a
join public.sga_albaran_historial h on h.albaran_id = a.id
where a.numero_texto in ('GLO13112026-1', 'GLO13112026-2', 'GLO13112026-3')
order by a.numero_texto, h.created_at;

-- BLOQUE 5: los datos de los artículos de esos albaranes (lo que sale impreso en el albarán: medidas, peso, referencia…)
select a.numero_texto as albaran, ar.nombre as articulo, ar.referencia, ar.medidas, ar.peso, ar.metros_lineales, ar.bultos_por_unidad, ar.atributos, length(coalesce(ar.medidas, '')) as largo_medidas
from public.sga_albaranes a
join public.sga_movimientos m on m.albaran_id = a.id
join public.sga_partidas p on p.id = m.partida_id
join public.sga_articulos ar on ar.id = p.articulo_id
where a.numero_texto in ('GLO13112026-1', 'GLO13112026-2', 'GLO13112026-3')
order by a.numero_texto;

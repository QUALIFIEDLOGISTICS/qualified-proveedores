-- ============================================================
-- QUALIFIED PROVEEDORES — Diagnóstico (solo LEE, no cambia nada): qué le pasó a un albarán (historial) y dónde está su mercancía
-- Instrucciones: Supabase → SQL Editor. Cambia  GLO29102026-1  por el nº del albarán y pulsa Run. Ejecuta cada bloque por separado.
-- ============================================================

-- BLOQUE 1: su historial (quién lo creó, editó, confirmó o anuló, y cuándo)
select h.created_at, h.usuario, h.resumen
from public.sga_albaran_historial h
join public.sga_albaranes a on a.id = h.albaran_id
where a.numero_texto = 'GLO29102026-1'
order by h.created_at;

-- BLOQUE 2: su mercancía y en qué almacén figura ahora cada partida
select p.descripcion as articulo, p.referencia, w.name as almacen_de_la_partida, p.cantidad_actual as stock_que_queda, p.estado as estado_partida, -m.cantidad as palets_de_este_albaran
from public.sga_albaranes a
join public.sga_movimientos m on m.albaran_id = a.id and m.tipo = 'salida'
join public.sga_partidas p on p.id = m.partida_id
left join public.warehouses w on w.id = p.warehouse_id
where a.numero_texto = 'GLO29102026-1';

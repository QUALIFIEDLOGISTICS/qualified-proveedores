-- ============================================================
-- QUALIFIED PROVEEDORES — Diagnóstico (solo LEE, no cambia nada): borradores de expedición cuya mercancía ya no está en el almacén del borrador
-- Pasa cuando, después de preparar un borrador, la mercancía se traspasa a otro almacén (el traspaso mueve la partida entera) o el almacén se archiva.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================
select a.numero_texto as albaran, a.fecha, k.nombre as cliente,
       wa.name as almacen_del_borrador, wp.name as almacen_donde_esta_la_mercancia,
       -m.cantidad as palets_del_borrador, p.cantidad_actual as stock_que_queda_en_la_partida, p.estado as estado_partida
from public.sga_albaranes a
join public.sga_movimientos m on m.albaran_id = a.id and m.tipo = 'salida'
join public.sga_partidas p on p.id = m.partida_id
join public.contactos k on k.id = a.cliente_id
left join public.warehouses wa on wa.id = a.warehouse_id
left join public.warehouses wp on wp.id = p.warehouse_id
where a.tipo = 'salida' and a.estado = 'confirmado' and a.borrador and p.warehouse_id is distinct from a.warehouse_id
order by a.fecha desc;

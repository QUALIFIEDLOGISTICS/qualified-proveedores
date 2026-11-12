-- ============================================================
-- QUALIFIED PROVEEDORES — Diagnóstico (solo LEE, no cambia nada): todos los borradores de expedición y cuántas líneas y palets tiene cada uno
-- Sirve para ver si un borrador «vacío» tiene de verdad su mercancía guardada y en qué almacén está.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================
select a.numero_texto as albaran, a.fecha, k.nombre as cliente, wa.name as almacen_del_borrador,
       (select count(*) from public.sga_movimientos m where m.albaran_id = a.id and m.tipo = 'salida') as lineas,
       (select coalesce(-sum(m.cantidad), 0) from public.sga_movimientos m where m.albaran_id = a.id and m.tipo = 'salida') as palets,
       (select string_agg(distinct coalesce(w.name, p.warehouse_id), ', ')
          from public.sga_movimientos m join public.sga_partidas p on p.id = m.partida_id left join public.warehouses w on w.id = p.warehouse_id
         where m.albaran_id = a.id and m.tipo = 'salida') as almacen_de_la_mercancia
from public.sga_albaranes a
join public.contactos k on k.id = a.cliente_id
left join public.warehouses wa on wa.id = a.warehouse_id
where a.tipo = 'salida' and a.estado = 'confirmado' and a.borrador
order by a.fecha desc;

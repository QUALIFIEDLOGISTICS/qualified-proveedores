-- ============================================================
-- QUALIFIED PROVEEDORES — Diagnóstico (solo LEE, no cambia nada): los últimos albaranes de un cliente, con su estado, líneas y palets
-- Sirve para encontrar un albarán que «no aparece»: si está anulado, si ya no es borrador, de qué almacén es y si conserva su mercancía.
-- Instrucciones: Supabase → SQL Editor. Cambia  CLIENTE  por una parte del nombre del cliente (p. ej. GLOBO) y pulsa Run.
-- ============================================================
select a.numero_texto as albaran, a.fecha, a.tipo, a.estado, a.borrador, wa.name as almacen, a.created_at::date as creado, a.anulado_motivo,
       (select count(*) from public.sga_movimientos m where m.albaran_id = a.id and m.tipo in ('salida', 'entrada', 'apertura')) as lineas,
       (select coalesce(sum(abs(m.cantidad)), 0) from public.sga_movimientos m where m.albaran_id = a.id and m.tipo in ('salida', 'entrada', 'apertura')) as palets
from public.sga_albaranes a
join public.contactos k on k.id = a.cliente_id
left join public.warehouses wa on wa.id = a.warehouse_id
where k.nombre ilike '%CLIENTE%' or coalesce(k.nombre_comercial, '') ilike '%CLIENTE%'
order by a.created_at desc
limit 30;

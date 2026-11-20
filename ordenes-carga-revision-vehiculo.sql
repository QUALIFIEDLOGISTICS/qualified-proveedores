-- ============================================================
-- QUALIFIED PROVEEDORES — Órdenes de carga · Revisión de las que no tienen vehículo (SOLO LEE, no cambia nada)
-- Para ver qué órdenes están sin vehículo, cuándo y cómo se crearon (desde el formulario de Órdenes o desde una expedición del SGA).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Salen 2 tablas (usa las pestañas de resultados).
-- ============================================================

-- 1) Resumen: cuántas órdenes hay sin vehículo y cuál es la última que se creó así
select count(*)                                                            as ordenes_en_total,
       count(*) filter (where coalesce(trim(tipo_vehiculo), '') = '')      as sin_vehiculo,
       max(created_at) filter (where coalesce(trim(tipo_vehiculo), '') = '') as ultima_creada_sin_vehiculo,
       max(created_at)                                                     as ultima_creada
from public.ordenes_carga;

-- 2) Las órdenes sin vehículo, de la más reciente a la más antigua
--    (con expedición = salió del SGA; sin ella = se creó en el formulario de Órdenes de carga)
select numero, fecha_pedido, estado, servicio, created_at, created_by,
       case when albaran_id is null then 'formulario de Órdenes' else 'expedición del SGA' end as origen,
       updated_at
from public.ordenes_carga
where coalesce(trim(tipo_vehiculo), '') = ''
order by created_at desc
limit 30;

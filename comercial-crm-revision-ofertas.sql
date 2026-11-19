-- ============================================================
-- QUALIFIED PROVEEDORES — CRM · Revisión de las ofertas guardadas (SOLO LEE, no cambia nada)
-- Para ver cuántas cotizaciones y cuántos números de oferta (OF-2026-NNNN) hay de verdad en la base de datos.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Salen 3 tablas (usa las pestañas de resultados).
-- ============================================================

-- 1) Resumen: cuántas cotizaciones hay, cuántas tienen número de oferta y cuál es el último
select count(*)                                   as cotizaciones_en_total,
       count(oferta)                              as con_numero_de_oferta,
       max(oferta)                                as ultimo_numero,
       count(*) filter (where fase = 'cotizada')  as en_fase_cotizada,
       count(*) filter (where fase not in ('ganada', 'perdida')) as abiertas,
       count(*) filter (where fase = 'ganada')    as ganadas,
       count(*) filter (where fase = 'perdida')   as perdidas
from public.crm_oportunidades;

-- 2) Números de oferta de este año que NO existen (huecos) entre el 1 y el último
with usados as (
  select substring(oferta from '(\d+)$')::int as n from public.crm_oportunidades where oferta like 'OF-' || to_char(now(), 'YYYY') || '-%'
)
select g as numero_que_falta, 'OF-' || to_char(now(), 'YYYY') || '-' || lpad(g::text, 4, '0') as oferta
from generate_series(1, (select coalesce(max(n), 0) from usados)) g
where g not in (select n from usados)
order by 1;

-- 3) Las últimas 20 cotizaciones, para compararlas con lo que ves en pantalla
select oferta, oferta_fecha, fecha_cotizacion, fase, servicio, left(coalesce(titulo, ''), 40) as titulo, created_at, created_by
from public.crm_oportunidades
order by created_at desc
limit 20;

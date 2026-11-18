-- ============================================================
-- QUALIFIED PROVEEDORES — Órdenes de carga: poner «España» como país del destino a las 6 órdenes LTL que lo tienen vacío
-- (17, 28, 32, 33, 34 y 38) y devolver el cero inicial a los códigos postales que lo perdieron (9433 → 09433).
-- Sin país en la última descarga, la orden no puede convertirse en cobertura de la Red de Transportistas.
-- Solo toca la ÚLTIMA descarga de esas 6 órdenes y solo si su país está vacío. Después hay que repetir «Coberturas desde las OC».
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

update public.ordenes_carga
set descargas = jsonb_set(
      jsonb_set(descargas, '{-1,pais}', '"España"'),
      '{-1,cp}', to_jsonb(lpad(regexp_replace(coalesce(descargas->-1->>'cp', ''), '\D', '', 'g'), 5, '0')))
where numero in (17, 28, 32, 33, 34, 38)
  and coalesce(descargas->-1->>'pais', '') = '';

-- Comprobación: deben salir las 6 con país España y el CP de 5 cifras
select numero, transportista_nombre, descargas->-1->>'pais' as pais_destino, descargas->-1->>'cp' as cp_destino
from public.ordenes_carga where numero in (17, 28, 32, 33, 34, 38) order by numero;

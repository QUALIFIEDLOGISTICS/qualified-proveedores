-- ============================================================
-- QUALIFIED PROVEEDORES — Red de Transportistas: «Grúa» como vehículo.
-- Pone el vehículo «Grúa» a las coberturas de grúa que no lo tienen. Solo rellena tipo_vehiculo donde está vacío.
-- Opcional: el panel ya las trata como «Grúa» aunque no se ejecute; esto deja el dato guardado.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

update public.transportista_rutas set tipo_vehiculo = 'Grúa'
where 'GRUA' = any(servicios) and (tipo_vehiculo is null or tipo_vehiculo = '');

-- Comprobación: cuántas coberturas hay de cada vehículo
select coalesce(tipo_vehiculo, '(sin vehículo)') as vehiculo, count(*) as coberturas
from public.transportista_rutas group by 1 order by 2 desc;

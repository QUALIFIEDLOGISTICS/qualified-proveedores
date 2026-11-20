-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: marcar como PAGADOS al proveedor y COBRADOS al cliente todos los viajes hasta hoy
-- Para empezar de cero con los filtros «Pendientes de pagar»: todo lo que ya existe se da por pagado y cobrado,
-- y a partir de ahora solo salen pendientes los viajes nuevos. No toca las facturas (facturado / nº de factura) ni los viajes con fecha futura.
-- Es seguro ejecutarlo más de una vez. OJO: no se puede saber después cuáles estaban pendientes antes de ejecutarlo.
-- Requiere haber ejecutado antes forrajes-pagado-cobrado.sql (las dos columnas nuevas).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
with cambiados as (
  update public.forraje_viajes
  set pagado_proveedor = true,
      cobrado_cliente = true
  where fecha <= current_date
    and (pagado_proveedor is not true or cobrado_cliente is not true)
  returning id
)
select (select count(*) from cambiados) as viajes_marcados,
       (select count(*) from public.forraje_viajes) as viajes_en_total,
       (select count(*) from public.forraje_viajes where fecha > current_date) as con_fecha_futura_sin_tocar;

-- Comprobación (ejecútalo después, aparte): debe salir 0 pendientes hasta hoy
-- select count(*) as pendientes from public.forraje_viajes where fecha <= current_date and (pagado_proveedor is not true or cobrado_cliente is not true);

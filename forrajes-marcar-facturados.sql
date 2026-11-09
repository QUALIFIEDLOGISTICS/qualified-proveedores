-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: marcar TODOS los viajes como facturados (por el proveedor y al cliente)
-- Solo cambia la casilla de «facturado» de los viajes que aún no la tenían; no toca los números de factura que ya hubiera.
-- Es seguro ejecutarlo más de una vez. OJO: no se puede saber después cuáles estaban pendientes antes de ejecutarlo.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
with cambiados as (
  update public.forraje_viajes
  set facturado_proveedor = true,
      facturado_cliente = true
  where facturado_proveedor is not true or facturado_cliente is not true
  returning id
)
select (select count(*) from cambiados) as viajes_marcados,
       (select count(*) from public.forraje_viajes) as viajes_en_total;

-- Comprobación (ejecútalo después, aparte): debe salir 0 pendientes
-- select count(*) as pendientes from public.forraje_viajes where facturado_proveedor is not true or facturado_cliente is not true;

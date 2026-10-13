-- =====================================================================
-- Órdenes de carga · datos internos (no salen en el PDF)
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
--
--   cliente_id       Ya existía: el cliente al que se le vende el transporte (se elige en «Datos internos»).
--   precio_cliente   Lo que nos paga el cliente, en EUR (el campo «precio» de siempre es lo que se paga al transportista).
--   servicio         FTL (camión completo) o LTL (grupaje).
--   metros           Metros de carga, del 1 al 13.
-- =====================================================================

alter table public.ordenes_carga add column if not exists precio_cliente numeric(12,2);
alter table public.ordenes_carga add column if not exists servicio text;
alter table public.ordenes_carga add column if not exists metros smallint;

alter table public.ordenes_carga drop constraint if exists ordenes_carga_servicio_check;
alter table public.ordenes_carga add constraint ordenes_carga_servicio_check check (servicio is null or servicio in ('FTL', 'LTL'));
alter table public.ordenes_carga drop constraint if exists ordenes_carga_metros_check;
alter table public.ordenes_carga add constraint ordenes_carga_metros_check check (metros is null or (metros between 1 and 13));

-- =====================================================================
-- Órdenes de carga · Otros costes de la orden (solo internos, no salen en el PDF)
-- Para anotar lo que se paga además del transportista de la orden: un segundo transportista, una grúa, una carretilla en la descarga…
-- No crea otra orden: son líneas dentro de la misma, que restan del margen.
-- Cada línea: { "concepto": "Grúa", "proveedor": "Grúas Y", "importe": 150 }
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
-- =====================================================================

alter table public.ordenes_carga add column if not exists costes_extra jsonb not null default '[]'::jsonb;

notify pgrst, 'reload schema';

-- Comprobación: debe salir 1 fila
select column_name, data_type from information_schema.columns
where table_schema = 'public' and table_name = 'ordenes_carga' and column_name = 'costes_extra';

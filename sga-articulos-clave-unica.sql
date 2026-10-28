-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Qué hace único a un artículo
-- Hasta ahora un cliente no podía tener dos artículos con el mismo código de artículo. Con esto, cada cliente puede elegir (en su ficha SGA,
-- «Un artículo es único por») datos de su catálogo que, junto al código, distinguen a un artículo: p. ej. el lote (mismo código con otro lote
-- = otro artículo). Lo que distingue a cada artículo se guarda en clave_extra; si el cliente no usa nada, queda vacío y todo sigue como antes.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
alter table public.sga_articulos add column if not exists clave_extra text not null default '';
drop index if exists public.sga_articulos_unico;
drop index if exists public.sga_articulos_codigo_unico;
create unique index if not exists sga_articulos_codigo_unico on public.sga_articulos (cliente_id, lower(nombre), lower(clave_extra));
notify pgrst, 'reload schema';

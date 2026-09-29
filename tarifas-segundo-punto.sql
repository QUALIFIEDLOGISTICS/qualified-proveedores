-- ============================================================
-- QUALIFIED PROVEEDORES — Tarifas: un viaje a veces recoge en 2 sitios
-- (o entrega en 2 sitios) en vez de uno solo. Se añade un segundo Origen
-- y un segundo Destino, opcionales, con la misma información que el
-- primero (zona, CP, ciudad).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.tarifas add column if not exists origen2_zona text;
alter table public.tarifas add column if not exists origen2_cp text;
alter table public.tarifas add column if not exists origen2_ciudad text;
alter table public.tarifas add column if not exists destino2_zona text;
alter table public.tarifas add column if not exists destino2_cp text;
alter table public.tarifas add column if not exists destino2_ciudad text;

-- ============================================================
-- QUALIFIED PROVEEDORES — DeCA con varias entregas para el mismo cliente
-- (mismo cargador/transportista/origen/mercancía/matrículas, pero el
-- camión reparte en 2 o 3 sitios distintos). Son varios DeCA a efectos
-- legales, pero se piden con UN SOLO número y UN SOLO QR, en un único
-- PDF con una página por entrega (la primera entrega sigue siendo el
-- campo "destino" de siempre; esta columna solo guarda las entregas
-- EXTRA, 2ª, 3ª...).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.deca_documents add column if not exists destinos_extra text[] not null default '{}';

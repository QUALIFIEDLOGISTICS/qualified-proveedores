-- ============================================================
-- QUALIFIED PROVEEDORES — DeCA con varios puntos de carga, simétrico a
-- las entregas adicionales (destinos_extra). El camión puede recoger en
-- 2 o 3 sitios antes de entregar, o incluso combinar varias cargas y
-- varias entregas a la vez en el mismo DeCA (mismo número, mismo QR):
-- esta columna guarda las cargas EXTRA, 2ª, 3ª... — "origen" sigue
-- siendo siempre la primera.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.deca_documents add column if not exists origenes_extra text[] not null default '{}';

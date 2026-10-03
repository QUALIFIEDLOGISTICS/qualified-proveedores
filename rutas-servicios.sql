-- ============================================================
-- QUALIFIED PROVEEDORES — Rutas: tipo de servicio de cada cobertura
-- (camión completo, grupaje, piso móvil / granel y grúa), los mismos tipos
-- que ya usa Tarifas Transporte (FTL, LTL, GRANEL, GRUA). Se pueden marcar
-- varios en la misma cobertura, salvo la grúa que va sola: no es una ruta
-- A → B sino una zona de servicio con tarifa por horas (se guarda con
-- destino = origen). Las coberturas que ya existen quedan "sin indicar"
-- (lista vacía) hasta que se marquen.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.transportista_rutas add column if not exists servicios text[] not null default '{}';

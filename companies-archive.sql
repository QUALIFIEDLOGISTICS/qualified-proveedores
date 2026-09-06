-- ============================================================
-- QUALIFIED PROVEEDORES — archivar empresas (Autónomos), igual
-- que ya se puede archivar un conductor. No se deja archivar una
-- empresa con conductores activos (se valida en el frontend).
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

alter table public.companies
  add column if not exists archived boolean not null default false;

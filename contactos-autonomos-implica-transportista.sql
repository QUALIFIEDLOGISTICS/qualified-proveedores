-- ============================================================
-- QUALIFIED PROVEEDORES — todo contacto Autónomos es también
-- Transportista (son las empresas de transporte que trabajan para
-- Qualified Logistics, y para eso hace falta que tengan camión).
-- Corrige los contactos migrados desde "companies" que se
-- marcaron solo como Autónomos.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

update public.contactos set es_transportista = true where es_autonomos = true and not es_transportista;

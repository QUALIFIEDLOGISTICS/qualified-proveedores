-- ============================================================
-- QUALIFIED PROVEEDORES — Almacén · Costes: permitir descuentos (importes que se restan).
-- Quita la regla «el importe no puede ser negativo»: un descuento o una bonificación se guarda con importe negativo
-- (en el formulario se marca «Es un descuento» y se escribe en positivo). No cambia ningún dato existente.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.almacen_costes drop constraint if exists almacen_costes_importe_check;

notify pgrst, 'reload schema';

-- Comprobación: ya no debe salir ninguna regla sobre el importe
select conname from pg_constraint where conrelid = 'public.almacen_costes'::regclass and contype = 'c' and pg_get_constraintdef(oid) ilike '%importe%';

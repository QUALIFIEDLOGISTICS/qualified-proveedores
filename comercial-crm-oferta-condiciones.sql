-- CRM · condiciones de la oferta en PDF: validez en días (por defecto 30) e indexación de gasoil del transporte.
-- gasoil: 'si' = los precios llevan indexación de gasoil, 'no' = no la llevan, vacío = no se indica.
-- Es seguro ejecutarlo más de una vez.

alter table public.crm_oportunidades add column if not exists oferta_validez_dias integer;
alter table public.crm_oportunidades add column if not exists gasoil text;

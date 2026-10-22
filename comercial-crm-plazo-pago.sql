-- CRM · plazo de pago de la cotización (opcional). Sale en las condiciones del PDF de la oferta.
-- Es seguro ejecutarlo más de una vez.

alter table public.crm_oportunidades add column if not exists plazo_pago text;

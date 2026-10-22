-- CRM · cargo de la persona de contacto (cotizaciones y prospectos) y texto de la solicitud del cliente
-- (el correo o mensaje que se pega al abrir una cotización). Es seguro ejecutarlo más de una vez.

alter table public.crm_oportunidades add column if not exists cargo text;
alter table public.crm_oportunidades add column if not exists solicitud text;
alter table public.crm_prospectos add column if not exists cargo text;

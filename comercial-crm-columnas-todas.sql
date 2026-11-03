-- Todo lo que necesita el CRM para guardar cotizaciones y prospectos. Se puede ejecutar las veces que haga falta: solo añade o corrige lo que falte.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.

-- Cotizaciones
alter table public.crm_oportunidades add column if not exists conceptos jsonb not null default '[]'::jsonb;
alter table public.crm_oportunidades add column if not exists importe_rec numeric(12,2);
alter table public.crm_oportunidades add column if not exists oferta text;
alter table public.crm_oportunidades add column if not exists oferta_fecha date;
alter table public.crm_oportunidades add column if not exists cargo text;
alter table public.crm_oportunidades add column if not exists solicitud text;
alter table public.crm_oportunidades add column if not exists oferta_validez_dias integer;
alter table public.crm_oportunidades add column if not exists gasoil text;
alter table public.crm_oportunidades add column if not exists plazo_pago text;
alter table public.crm_oportunidades add column if not exists empresa_nombre text;

-- Prospectos
alter table public.crm_prospectos add column if not exists persona text;
alter table public.crm_prospectos add column if not exists cargo text;
alter table public.crm_prospectos add column if not exists telefono text;
alter table public.crm_prospectos add column if not exists email text;
alter table public.crm_prospectos add column if not exists servicio text;
alter table public.crm_prospectos add column if not exists potencial text;
alter table public.crm_prospectos add column if not exists interes text;
alter table public.crm_prospectos add column if not exists revisar_el date;

-- Una cotización puede ser de una empresa que aún no está en Clientes ni en Prospectos: entonces solo lleva su nombre (empresa_nombre).
-- La regla antigua exigía siempre un prospecto o un cliente y por eso no dejaba guardar esas cotizaciones.
alter table public.crm_oportunidades drop constraint if exists crm_oportunidades_empresa;
alter table public.crm_oportunidades add constraint crm_oportunidades_empresa
  check (prospecto_id is not null or contacto_id is not null or nullif(btrim(empresa_nombre), '') is not null);

notify pgrst, 'reload schema';

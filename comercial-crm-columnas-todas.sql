-- Todas las columnas que usa la cotización del CRM. Se puede ejecutar las veces que haga falta: solo añade lo que falte.
alter table public.crm_oportunidades add column if not exists conceptos jsonb not null default '[]'::jsonb;
alter table public.crm_oportunidades add column if not exists importe_rec numeric(12,2);
alter table public.crm_oportunidades add column if not exists oferta text;
alter table public.crm_oportunidades add column if not exists oferta_fecha date;
alter table public.crm_oportunidades add column if not exists cargo text;
alter table public.crm_oportunidades add column if not exists solicitud text;
alter table public.crm_oportunidades add column if not exists oferta_validez_dias integer;
alter table public.crm_oportunidades add column if not exists gasoil text;
alter table public.crm_oportunidades add column if not exists plazo_pago text;
alter table public.crm_prospectos add column if not exists cargo text;
notify pgrst, 'reload schema';

-- CRM · prospectos «a futuro»: empresas que no se quieren cotizar ahora pero interesan a largo plazo.
-- Guarda quién es el contacto, qué servicio les interesaría, cuánto potencial tienen, por qué interesan
-- y cuándo hay que volver a mirarlas (esa fecha hace que aparezcan en «Hoy»).
-- Es seguro ejecutarlo más de una vez.

alter table public.crm_prospectos add column if not exists persona text;
alter table public.crm_prospectos add column if not exists telefono text;
alter table public.crm_prospectos add column if not exists email text;
alter table public.crm_prospectos add column if not exists servicio text;
alter table public.crm_prospectos add column if not exists potencial text;
alter table public.crm_prospectos add column if not exists interes text;
alter table public.crm_prospectos add column if not exists revisar_el date;

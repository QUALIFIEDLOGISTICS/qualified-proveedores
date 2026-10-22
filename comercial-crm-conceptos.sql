-- Comercial → CRM: líneas de cada cotización (rutas de transporte y productos de almacén) y el importe mensual
alter table public.crm_oportunidades add column if not exists conceptos jsonb not null default '[]'::jsonb;
alter table public.crm_oportunidades add column if not exists importe_rec numeric(12,2);
notify pgrst, 'reload schema';

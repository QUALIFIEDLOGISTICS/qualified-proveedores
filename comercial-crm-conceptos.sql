-- Comercial → CRM: lo que se cotiza, elegido de los catálogos de Tarifas Transporte y Tarifas Almacén
alter table public.crm_oportunidades add column if not exists conceptos jsonb not null default '[]'::jsonb;
notify pgrst, 'reload schema';

-- CRM · número de oferta de cada cotización (para el PDF que se le pasa al cliente).
-- Formato OF-AAAA-NNNN (OF-2026-0001, OF-2026-0002…). Se asigna al generar el PDF por primera vez y no cambia.
-- Es seguro ejecutarlo más de una vez.

alter table public.crm_oportunidades add column if not exists oferta text;
alter table public.crm_oportunidades add column if not exists oferta_fecha date;

create unique index if not exists crm_oportunidades_oferta_uq
  on public.crm_oportunidades (oferta)
  where oferta is not null;

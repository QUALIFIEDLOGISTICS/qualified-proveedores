-- Tarifas: nuevo tipo de camión "Grúa".
alter table public.tarifas drop constraint if exists tarifas_tipo_check;
alter table public.tarifas add constraint tarifas_tipo_check check (tipo in ('FTL', 'LTL', 'GRANEL', 'GRUA'));

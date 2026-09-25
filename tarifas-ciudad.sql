-- Tarifas: ciudad de origen y de destino (se rellena a partir del CP).
alter table public.tarifas add column if not exists origen_ciudad text;
alter table public.tarifas add column if not exists destino_ciudad text;

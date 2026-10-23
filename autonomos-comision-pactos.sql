-- Autónomos · Piso Móvil: pactos / observaciones junto a cada comisión (igual que las tarifas de Plaza)
alter table public.mobile_commission_rates add column if not exists note text;

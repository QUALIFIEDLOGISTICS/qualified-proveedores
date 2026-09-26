-- Almacenes: dirección del almacén (para poder usarla más adelante en los albaranes de salida).
alter table public.warehouses add column if not exists calle1 text;
alter table public.warehouses add column if not exists calle2 text;
alter table public.warehouses add column if not exists codigo_postal text;
alter table public.warehouses add column if not exists ciudad text;
alter table public.warehouses add column if not exists provincia text;
alter table public.warehouses add column if not exists pais text;

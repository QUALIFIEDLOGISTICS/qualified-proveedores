-- Autónomos · Incidencias como aviso: quién la crea y si ya está resuelta
alter table public.daily_incidents add column if not exists created_by text;
alter table public.daily_incidents add column if not exists resuelta boolean not null default false;

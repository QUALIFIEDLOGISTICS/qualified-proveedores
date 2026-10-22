-- Transporte → Mapa: importación del listado de AS24 (código, CP, estado, avisos, reserva y combustibles de cada sitio)
alter table public.transporte_puntos add column if not exists codigo text;
alter table public.transporte_puntos add column if not exists cp text;
alter table public.transporte_puntos add column if not exists estado text;
alter table public.transporte_puntos add column if not exists aviso text;
alter table public.transporte_puntos add column if not exists reserva text;
alter table public.transporte_puntos add column if not exists combustibles jsonb not null default '[]'::jsonb;
alter table public.transporte_puntos add column if not exists maps_url text;
create unique index if not exists transporte_puntos_codigo_uq on public.transporte_puntos (codigo);
notify pgrst, 'reload schema';

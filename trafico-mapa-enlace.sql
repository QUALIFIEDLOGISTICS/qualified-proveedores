-- Transporte → Mapa: enlace de Google Maps de cada punto
alter table public.transporte_puntos add column if not exists maps_url text;
notify pgrst, 'reload schema';

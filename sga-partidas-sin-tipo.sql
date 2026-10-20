-- Recepciones sin «Tipo de carga» (clientes que cobran por m²)
alter table public.sga_partidas alter column producto_id drop not null;
notify pgrst, 'reload schema';

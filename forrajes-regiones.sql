-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: región de cada viaje con el formato de Transporte (país + número)
-- F-31 → FR31, F-09 → FR09, E-25 → ES25, E-08 → ES08…  Se aplica a las regiones de carga y de descarga de los viajes.
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
update public.forraje_viajes
set zona_carga = case
      when zona_carga ~* '^F-?[0-9]+$' then 'FR' || regexp_replace(zona_carga, '[^0-9]', '', 'g')
      when zona_carga ~* '^E-?[0-9]+$' then 'ES' || regexp_replace(zona_carga, '[^0-9]', '', 'g')
      else zona_carga end,
    zona_descarga = case
      when zona_descarga ~* '^F-?[0-9]+$' then 'FR' || regexp_replace(zona_descarga, '[^0-9]', '', 'g')
      when zona_descarga ~* '^E-?[0-9]+$' then 'ES' || regexp_replace(zona_descarga, '[^0-9]', '', 'g')
      else zona_descarga end
where zona_carga ~* '^[FE]-?[0-9]+$' or zona_descarga ~* '^[FE]-?[0-9]+$';

notify pgrst, 'reload schema';

-- Comprobación: regiones de carga que hay ahora en los viajes
select zona_carga as region, count(*) as viajes from public.forraje_viajes group by 1 order by 2 desc;

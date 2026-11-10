-- ============================================================
-- QUALIFIED PROVEEDORES — «De dónde es» cada conductor (ciudad o código postal)
-- Dato fijo de la ficha del conductor, para saber de qué zona es y poder ver
-- dónde le queda cerca su casa para que duerma en ella los días que haga falta.
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
alter table public.drivers add column if not exists residencia text;

notify pgrst, 'reload schema';

-- Comprobación: debe salir 1 fila
select column_name from information_schema.columns
where table_schema = 'public' and table_name = 'drivers' and column_name = 'residencia';

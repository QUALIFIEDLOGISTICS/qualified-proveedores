-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Poder corregir/borrar las tarifas de un cliente aunque ya tenga expediciones
-- Cada cobro apunta a la línea de tarifa con la que se calculó (sga_cobros.tarifa_id). Mientras ese enlace sea
-- obligatorio, la base de datos NO deja borrar una línea de tarifa que ya se ha usado en alguna expedición.
-- Con este cambio, al borrar la línea el cobro se queda como está (mismo precio e importe) y solo pierde el enlace.
-- No toca ningún dato existente. Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

do $$
declare c record;
begin
  for c in
    select con.conname
    from pg_constraint con
    where con.conrelid = 'public.sga_cobros'::regclass
      and con.contype = 'f'
      and con.confrelid = 'public.almacenaje_tarifas'::regclass
  loop
    execute format('alter table public.sga_cobros drop constraint %I', c.conname);
  end loop;
end $$;

alter table public.sga_cobros
  add constraint sga_cobros_tarifa_id_fkey
  foreign key (tarifa_id) references public.almacenaje_tarifas(id) on delete set null;

notify pgrst, 'reload schema';

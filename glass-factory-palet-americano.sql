-- ============================================================
-- QUALIFIED PROVEEDORES — GLASS FACTORY: «Entrada/Salida Palet» pasan a «Entrada/Salida Palet Americano»
-- Así su tarifa deja de tener productos cuyo nombre empieza igual («Entrada Palet» y «Entrada Palet Especial»), que es lo que hacía
-- salir el «Tipo de palet» (Normal / Especial) duplicado con el tipo de carga. Los productos «Entrada Palet» y «Salida Palet» NO se tocan
-- (los siguen usando ALMALIFT, KUKA ROBOTS y otros clientes).
--
-- Qué hace, todo en un solo paso (si algo falla, no se cambia nada):
--  1) Comprueba que ningún otro cliente usa el producto de stock «Palet Americano» (id palet_especial): si lo usara, aborta sin cambiar nada.
--  2) Guarda una copia de lo que va a tocar (tablas almacenaje_tarifas_bak_americano y almacenaje_productos_bak_americano).
--  3) Crea los productos «Entrada Palet Americano» y «Salida Palet Americano» (copia de «Entrada Palet» y «Salida Palet», solo cambia el nombre).
--  4) Hace que «Palet Americano» (stock) cobre la entrada y la salida con esos productos nuevos.
--  5) Pasa las líneas de tarifa de GLASS FACTORY de «Entrada Palet» / «Salida Palet» a los nuevos (mismo precio y fecha, mismo id de línea).
-- Los cobros ya hechos no cambian. Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
do $$
declare
  glass uuid;
  n int;
  otros_t int;
  otros_p int;
begin
  select count(*), min(id::text)::uuid into n, glass
    from public.contactos where nombre ilike '%glass factory%' or nombre_comercial ilike '%glass factory%';
  if n <> 1 then
    raise exception 'Se esperaba encontrar un solo cliente «GLASS FACTORY» y hay %: no se ha cambiado nada.', n;
  end if;

  select count(*) into otros_t from public.almacenaje_tarifas where tipo = 'palet_especial' and cliente_id <> glass;
  select count(*) into otros_p from public.sga_partidas where producto_id = 'palet_especial' and cliente_id <> glass;
  if otros_t > 0 or otros_p > 0 then
    raise exception 'Otros clientes usan el producto «Palet Americano» (% líneas de tarifa, % partidas): cambiar su enlace les afectaría. No se ha cambiado nada.', otros_t, otros_p;
  end if;

  -- 2) Copia de seguridad (con la seguridad de filas activada y sin accesos: solo se lee desde el SQL Editor)
  create table if not exists public.almacenaje_tarifas_bak_americano as select * from public.almacenaje_tarifas where false;
  create table if not exists public.almacenaje_productos_bak_americano as select * from public.almacenaje_productos where false;
  alter table public.almacenaje_tarifas_bak_americano enable row level security;
  alter table public.almacenaje_productos_bak_americano enable row level security;
  insert into public.almacenaje_tarifas_bak_americano
    select t.* from public.almacenaje_tarifas t
    where t.cliente_id = glass and t.tipo in ('entrada', 'salida')
      and not exists (select 1 from public.almacenaje_tarifas_bak_americano b where b.id = t.id);
  insert into public.almacenaje_productos_bak_americano
    select p.* from public.almacenaje_productos p
    where p.id = 'palet_especial'
      and not exists (select 1 from public.almacenaje_productos_bak_americano b where b.id = p.id);

  -- 3) Productos nuevos (copia de los actuales, solo cambia el nombre)
  insert into public.almacenaje_productos (id, nombre, categoria, unidad, usa_subtipo, subtipo_label, subtipo_valor, disparador, familia, cobro_entrada, cobro_salida, archived)
    select 'entrada_americano', 'Entrada Palet Americano', categoria, unidad, usa_subtipo, subtipo_label, subtipo_valor, disparador, familia, cobro_entrada, cobro_salida, archived
    from public.almacenaje_productos where id = 'entrada'
  on conflict (id) do nothing;
  insert into public.almacenaje_productos (id, nombre, categoria, unidad, usa_subtipo, subtipo_label, subtipo_valor, disparador, familia, cobro_entrada, cobro_salida, archived)
    select 'salida_americano', 'Salida Palet Americano', categoria, unidad, usa_subtipo, subtipo_label, subtipo_valor, disparador, familia, cobro_entrada, cobro_salida, archived
    from public.almacenaje_productos where id = 'salida'
  on conflict (id) do nothing;

  -- 4) «Palet Americano» (stock) cobra la entrada y la salida con los productos nuevos
  update public.almacenaje_productos set cobro_entrada = 'entrada_americano', cobro_salida = 'salida_americano' where id = 'palet_especial';

  -- 5) Las líneas de tarifa de GLASS FACTORY pasan a los productos nuevos
  update public.almacenaje_tarifas set tipo = 'entrada_americano' where cliente_id = glass and tipo = 'entrada';
  update public.almacenaje_tarifas set tipo = 'salida_americano' where cliente_id = glass and tipo = 'salida';
end $$;

notify pgrst, 'reload schema';

-- Para comprobar cómo ha quedado (ejecútalo aparte):
-- select p.nombre, p.disparador, p.cobro_entrada, p.cobro_salida, t.precio, t.fecha
-- from public.almacenaje_tarifas t join public.almacenaje_productos p on p.id = t.tipo join public.contactos c on c.id = t.cliente_id
-- where c.nombre ilike '%glass%' order by p.disparador, p.nombre;

-- PARA DESHACERLO (solo si hiciera falta):
-- update public.almacenaje_tarifas t set tipo = b.tipo from public.almacenaje_tarifas_bak_americano b where t.id = b.id;
-- update public.almacenaje_productos p set cobro_entrada = b.cobro_entrada, cobro_salida = b.cobro_salida from public.almacenaje_productos_bak_americano b where p.id = b.id;

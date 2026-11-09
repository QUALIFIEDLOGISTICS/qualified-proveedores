-- ============================================================
-- QUALIFIED PROVEEDORES — Dashboard de almacén: que lo vea completo quien tenga ese permiso (solo lectura)
-- Problema: el permiso «Dashboard de almacén» dejaba entrar a la página, pero los datos (albaranes, cobros, clientes del SGA, tarifas…)
-- solo los podía leer quien tuviera «Control Stock SGA» u otros permisos. Sin ellos, Supabase devolvía las tablas vacías sin avisar
-- y el dashboard salía sin cifras.
-- Solución: se AÑADE a cada una de esas tablas una política de LECTURA para quien tenga «almacendash». No se quita ni se cambia ninguna
-- política que ya exista, y no se da permiso para crear, editar ni borrar nada.
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
do $$
declare t text;
begin
  foreach t in array array[
    'sga_albaranes', 'sga_partidas', 'sga_movimientos', 'sga_servicios', 'sga_cobros',   -- lo que se movió y se cobró
    'sga_m2', 'sga_m2_contrato', 'sga_operativas_realizadas',                              -- m² contratados y operativas
    'sga_clientes',                                                                        -- ajustes de cada cliente (desde cuándo se cobra…)
    'almacenaje_tarifas', 'almacenaje_productos',                                          -- tarifas con las que se calculan los ingresos
    'contacto_warehouses'                                                                  -- en qué almacén está cada cliente
  ] loop
    execute format('drop policy if exists %1$s_select_dashboard on public.%1$s', t);
    execute format('create policy %1$s_select_dashboard on public.%1$s for select using (public.sga_permiso(''almacendash''))', t);
  end loop;
end $$;

notify pgrst, 'reload schema';

-- Comprobación: deben salir 12 filas (una por tabla), todas de lectura (select)
select tablename, policyname, cmd
from pg_policies
where schemaname = 'public' and policyname like '%\_select\_dashboard'
order by tablename;

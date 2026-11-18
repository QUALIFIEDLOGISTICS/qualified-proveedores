-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes · Pagos: ahora se puede dar la pestaña «Pagos» a quien tú elijas (Gestión de Permisos → Forrajes → Pagos)
-- Hasta ahora las tablas de socios, porcentajes y pagos solo las leía y escribía un administrador. Con este cambio también pueden
-- una cuenta que tenga Forrajes Y el apartado «Forrajes · Pagos» marcado. Quien no lo tenga sigue sin poder ver nada.
-- Es seguro ejecutarlo más de una vez y no toca ningún dato.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
do $$
declare t text;
begin
  foreach t in array array['forraje_socios', 'forraje_pagos', 'forraje_socio_porcentajes', 'forraje_ajustes_mes'] loop
    if to_regclass('public.' || t) is not null then
      execute format('drop policy if exists %1$s_admin on public.%1$s', t);
      execute format('drop policy if exists %1$s_pagos on public.%1$s', t);
      execute format('create policy %1$s_pagos on public.%1$s for all using (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or (p.allowed_tabs ? ''forrajes'' and p.allowed_tabs ? ''forrajes:pagos'')))) with check (exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or (p.allowed_tabs ? ''forrajes'' and p.allowed_tabs ? ''forrajes:pagos''))))', t);
    end if;
  end loop;
end $$;

notify pgrst, 'reload schema';

-- Comprobación (solo lee): una política «_pagos» por tabla y ninguna «_admin»
select tablename, policyname from pg_policies where schemaname = 'public' and tablename in ('forraje_socios', 'forraje_pagos', 'forraje_socio_porcentajes', 'forraje_ajustes_mes') order by 1, 2;

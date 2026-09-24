-- ============================================================
-- QUALIFIED PROVEEDORES — Almacén → Configuración: dar de alta,
-- editar y archivar almacenes desde el panel.
-- 1) Columna "archived" (archivar un almacén sin perder su historial)
--    y "sort_order" (orden en el que salen en el selector).
-- 2) Los tres almacenes que ya existen conservan su orden actual.
-- 3) Solo un administrador puede crear, editar o borrar almacenes;
--    leerlos sigue abierto a cualquier cuenta con sesión, porque el
--    selector de almacén lo necesita todo el mundo.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.warehouses add column if not exists archived boolean not null default false;
alter table public.warehouses add column if not exists sort_order integer not null default 0;

update public.warehouses set sort_order = 1 where id = 'balsareny' and sort_order = 0;
update public.warehouses set sort_order = 2 where id = 'sant-fruitos' and sort_order = 0;
update public.warehouses set sort_order = 3 where id = 'pirelli-manresa' and sort_order = 0;

drop policy if exists warehouses_insert on public.warehouses;
drop policy if exists warehouses_update on public.warehouses;
drop policy if exists warehouses_delete on public.warehouses;

create policy warehouses_insert on public.warehouses for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
);
create policy warehouses_update on public.warehouses for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
);
create policy warehouses_delete on public.warehouses for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
);

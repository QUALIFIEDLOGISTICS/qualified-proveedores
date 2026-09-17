-- ============================================================
-- QUALIFIED PROVEEDORES — Unificación de Clientes y Empresas en
-- Contactos (paso 1 de 3): columnas nuevas + copia de datos.
-- NO DESTRUCTIVO — las tablas clients/companies siguen intactas
-- después de este paso, se borran en el paso 3.
--
-- IMPORTANTE: después de ejecutar este script, hay que desplegar
-- el panel.html actualizado (con los nuevos loaders/formularios)
-- ANTES de ejecutar el paso 2. No dejar la app a medias.
--
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez.
-- ============================================================

alter table public.contactos
  add column if not exists archived boolean not null default false,
  add column if not exists es_cliente_almacen boolean not null default false,
  add column if not exists es_transportista boolean not null default false,
  add column if not exists es_autonomos boolean not null default false;

create table if not exists public.contacto_warehouses (
  contacto_id uuid not null references public.contactos(id) on delete cascade,
  warehouse_id text not null references public.warehouses(id) on delete cascade,
  primary key (contacto_id, warehouse_id)
);
alter table public.contacto_warehouses enable row level security;

-- Clientes de almacén -> contactos (reutiliza el mismo id que ya tenían
-- en "clients", así las citas/palets/movimientos existentes no hay que
-- tocarlos: sus client_id siguen siendo válidos en cuanto la clave
-- foránea apunte a "contactos" en el paso 2).
insert into public.contactos (id, nombre, archived, es_cliente_almacen, created_at)
select id, name, archived, true, created_at from public.clients
on conflict (id) do update set es_cliente_almacen = true, archived = excluded.archived;

-- Empresas de autónomos -> contactos (mismo truco con companies.id).
insert into public.contactos (id, nombre, archived, es_autonomos, created_at)
select id, name, coalesce(archived,false), true, now() from public.companies
on conflict (id) do update set es_autonomos = true,
  archived = public.contactos.archived or excluded.archived;

-- Copia los almacenes asignados a cada cliente.
insert into public.contacto_warehouses (contacto_id, warehouse_id)
select client_id, warehouse_id from public.client_warehouses
on conflict do nothing;

-- ============================================================
-- QUALIFIED PROVEEDORES — Diagnóstico (solo LEE, no cambia nada): por qué una expedición no puede reservar su franja horaria
-- Error: «insert or update on table "unscheduled_trucks" violates foreign key constraint "unscheduled_trucks_client_id_fkey»
-- Significa que el cliente de la expedición no existe en la tabla a la que apunta esa clave de Franjas horarias.
-- Instrucciones: Supabase → SQL Editor. Cambia  UNNOX  por una parte del nombre del cliente. Ejecuta cada bloque por separado.
-- ============================================================

-- BLOQUE 1: ¿a qué tabla apunta la clave del cliente en Franjas horarias? (lo normal: contactos)
select conrelid::regclass as tabla, conname as clave, pg_get_constraintdef(oid) as definicion
from pg_constraint
where conname in ('unscheduled_trucks_client_id_fkey', 'appointments_client_id_fkey');

-- BLOQUE 2: el cliente tal como está en Contactos (su id es el que usa la expedición)
select id, nombre, nombre_comercial, archived, es_cliente_almacen
from public.contactos
where nombre ilike '%UNNOX%' or coalesce(nombre_comercial, '') ilike '%UNNOX%';

-- BLOQUE 3: ¿está también en la tabla antigua «clients»? (si el bloque 1 dice que la clave apunta a clients y aquí no sale, ahí está la causa)
select id, name from public.clients where name ilike '%UNNOX%';

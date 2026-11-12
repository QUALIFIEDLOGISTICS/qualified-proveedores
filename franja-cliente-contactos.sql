-- ============================================================
-- QUALIFIED PROVEEDORES — Franjas horarias: el cliente de una cita o de un camión sin hora es un Contacto
-- Problema: las claves «client_id» de appointments y unscheduled_trucks seguían apuntando a la tabla antigua «clients».
-- Un cliente que solo está en Contactos (creado después de la unificación) no podía tener franja horaria:
--   «insert or update on table "unscheduled_trucks" violates foreign key constraint "unscheduled_trucks_client_id_fkey"»
-- Este SQL repunta SOLO esas dos claves a Contactos (las mismas líneas que el paso 2 de la unificación, sin tocar nada más).
-- Instrucciones: Supabase → SQL Editor → pega cada bloque por separado → Run. Se puede ejecutar más de una vez.
-- ============================================================

-- BLOQUE 1 (solo lee): citas o camiones sin hora cuyo cliente NO está en Contactos. Debe salir 0 en las dos filas.
select 'appointments' as tabla, count(*) as sin_contacto from public.appointments a where not exists (select 1 from public.contactos c where c.id = a.client_id)
union all
select 'unscheduled_trucks', count(*) from public.unscheduled_trucks u where not exists (select 1 from public.contactos c where c.id = u.client_id);

-- BLOQUE 2 (el arreglo): si el bloque 1 dio 0, esto funciona. Si hubiera alguna fila sin contacto, da error y NO cambia nada.
alter table public.appointments drop constraint if exists appointments_client_id_fkey;
alter table public.appointments add constraint appointments_client_id_fkey
  foreign key (client_id) references public.contactos(id);

alter table public.unscheduled_trucks drop constraint if exists unscheduled_trucks_client_id_fkey;
alter table public.unscheduled_trucks add constraint unscheduled_trucks_client_id_fkey
  foreign key (client_id) references public.contactos(id);

notify pgrst, 'reload schema';

-- BLOQUE 3 (solo lee): ¿qué otras claves siguen apuntando a las tablas antiguas clients/companies? (pallets, movements, drivers… del paso 2 de la unificación)
select conrelid::regclass as tabla, conname as clave, pg_get_constraintdef(oid) as definicion
from pg_constraint
where contype = 'f'
  and confrelid in (select oid from pg_class where relnamespace = 'public'::regnamespace and relname in ('clients', 'companies'))
order by 1, 2;

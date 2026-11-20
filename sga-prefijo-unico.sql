-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Las letras del albarán no se pueden repetir entre clientes
-- La web ya lo comprueba al guardar la ficha SGA de un cliente; esta regla lo asegura también en la base de datos (por si alguien tiene abierta
-- una versión antigua de la web). Cuenta solo las letras guardadas (sin distinguir mayúsculas): las que un cliente usa «por defecto» sin tenerlas
-- guardadas las comprueba la web.
-- PASO 1 — comprueba si ya hay letras repetidas (solo lee). Si sale alguna fila, cambia las letras de esos clientes en su ficha SGA antes del PASO 2.
-- PASO 2 — crea la regla. Si todavía hubiera repetidas, Supabase lo rechaza y no cambia nada. Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

-- PASO 1: letras guardadas que usan 2 o más clientes (deben salir 0 filas)
select upper(prefijo) as letras, count(*) as clientes, string_agg(c.nombre, ' · ' order by c.nombre) as quienes
from public.sga_clientes s join public.contactos c on c.id = s.cliente_id
where coalesce(trim(s.prefijo), '') <> ''
group by upper(prefijo) having count(*) > 1;

-- PASO 2: la regla
create unique index if not exists sga_clientes_prefijo_uq on public.sga_clientes (upper(prefijo)) where coalesce(trim(prefijo), '') <> '';

notify pgrst, 'reload schema';

-- Comprobación: debe salir 1 fila (la regla)
select indexname from pg_indexes where schemaname = 'public' and indexname = 'sga_clientes_prefijo_uq';

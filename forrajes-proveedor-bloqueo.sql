-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: bloquear proveedores (mala calidad o cualquier otro motivo)
-- Un proveedor bloqueado sale en rojo en su lista, en los viajes y al elegirlo, con su motivo y la fecha en que se bloqueó.
-- No se borra nada: se puede desbloquear cuando quieras desde su ficha.
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
alter table public.forraje_proveedores add column if not exists bloqueado boolean not null default false;
alter table public.forraje_proveedores add column if not exists bloqueado_motivo text;
alter table public.forraje_proveedores add column if not exists bloqueado_en date;

notify pgrst, 'reload schema';

-- Comprobación: cuántos proveedores hay y cuántos bloqueados (ahora debe salir 0 bloqueados)
select count(*) as proveedores, count(*) filter (where bloqueado) as bloqueados from public.forraje_proveedores;

-- ============================================================
-- QUALIFIED PROVEEDORES — Rutas · cobertura automática desde las órdenes de carga (fase 1)
-- Solo AÑADE columnas (no borra ni cambia ningún dato). Se puede ejecutar más de una vez.
-- ANTES: haz una copia de seguridad (Supabase → Database → Backups).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
--
--   ordenes_carga.tipo_vehiculo      Tipo de vehículo de la orden (opcional; las antiguas quedan sin indicar).
--   transportista_rutas.fuente       'manual' (la apuntó una persona) o 'auto' (la creó el panel desde las órdenes).
--                                    Todas las que ya existen quedan como 'manual': nunca se sobrescriben, solo se actualizan sus estadísticas.
--   transportista_rutas.ultimo_precio  Último precio pagado al transportista en esa ruta.
--   transportista_rutas.ultimo_viaje   Fecha del último viaje.
--   transportista_rutas.n_viajes       Nº de viajes hechos.
--   transportista_rutas.margen_medio   Margen medio (% sobre lo cobrado).
-- ============================================================

alter table public.ordenes_carga add column if not exists tipo_vehiculo text;

alter table public.transportista_rutas add column if not exists fuente text not null default 'manual';
alter table public.transportista_rutas drop constraint if exists transportista_rutas_fuente_check;
alter table public.transportista_rutas add constraint transportista_rutas_fuente_check check (fuente in ('manual', 'auto'));
alter table public.transportista_rutas add column if not exists ultimo_precio numeric;
alter table public.transportista_rutas add column if not exists ultimo_viaje date;
alter table public.transportista_rutas add column if not exists n_viajes integer not null default 0;
alter table public.transportista_rutas add column if not exists margen_medio numeric;

notify pgrst, 'reload schema';

-- Comprobación: deben salir 6 filas
select table_name, column_name from information_schema.columns
where table_schema = 'public'
  and ((table_name = 'ordenes_carga' and column_name = 'tipo_vehiculo')
    or (table_name = 'transportista_rutas' and column_name in ('fuente', 'ultimo_precio', 'ultimo_viaje', 'n_viajes', 'margen_medio')))
order by table_name, column_name;

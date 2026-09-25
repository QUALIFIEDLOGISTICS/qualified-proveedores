-- Tarifas: fecha de referencia del gasoil (día en que se coge el valor para calcular la indexación).
alter table public.tarifas add column if not exists gasoil_fecha_ref date;

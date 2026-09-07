-- ============================================================
-- QUALIFIED PROVEEDORES — matrícula del camión que lleva cada
-- conductor, como dato fijo de su ficha (aparte de la matrícula
-- que se apunta en cada fichaje/reserva puntual).
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

alter table public.drivers
  add column if not exists truck_plate text;

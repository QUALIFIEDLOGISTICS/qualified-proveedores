-- ============================================================
-- QUALIFIED PROVEEDORES — cierre automático de fichajes olvidados
-- Si un conductor se deja una jornada de un día anterior sin
-- cerrar, la app la cierra sola al máximo de horas/km de su
-- tarifa de ese día (para no pagarle de más por un olvido) y la
-- marca con auto_closed para que se revise antes de pagarla.
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

alter table public.daily_entries
  add column if not exists auto_closed boolean not null default false;

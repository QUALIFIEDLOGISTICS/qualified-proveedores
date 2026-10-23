-- Autónomos · cada fichaje diario apunta de dónde viene: «manual» (lo ha metido una persona) o «quiosco» (lo ha fichado el conductor).
-- Cuando los fichajes entren solos desde el quiosco, la parrilla de Fichajes los distingue de los manuales.
-- Los fichajes que ya había se marcan así: con foto de inicio o de cierre = quiosco; sin fotos = manual.
-- Es seguro ejecutarlo más de una vez.

alter table public.daily_entries add column if not exists origen text;

update public.daily_entries
   set origen = case when photo_in_path is not null or photo_out_path is not null then 'quiosco' else 'manual' end
 where origen is null;

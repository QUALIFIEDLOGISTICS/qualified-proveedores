-- Autónomos · Incidencias: más tipos (accidente, retraso o espera, multa o sanción) además de avería, km de más por error y otro
alter table public.daily_incidents drop constraint if exists daily_incidents_type_check;
alter table public.daily_incidents add constraint daily_incidents_type_check
  check (type in ('averia','accidente','retraso','multa','km_error','otro'));

-- ============================================================
-- QUALIFIED PROVEEDORES — SGA: se puede crear solo una nave (sin zona), solo una zona (sin nave) o las dos.
-- Antes el nombre de la zona era obligatorio. Ahora basta con rellenar la nave o la zona.
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================
alter table public.sga_zonas alter column nombre drop not null;

alter table public.sga_zonas drop constraint if exists sga_zonas_nave_o_nombre;
alter table public.sga_zonas add constraint sga_zonas_nave_o_nombre check (nave is not null or nombre is not null);

drop index if exists public.sga_zonas_unica;
create unique index if not exists sga_zonas_unica
  on public.sga_zonas (warehouse_id, coalesce(lower(nave), ''), coalesce(lower(nombre), ''));

notify pgrst, 'reload schema';

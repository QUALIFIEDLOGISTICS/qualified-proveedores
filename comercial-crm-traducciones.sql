-- ============================================================
-- QUALIFIED PROVEEDORES — Comercial → CRM: traducciones de los nombres de productos y operativas para el PDF de la oferta
-- Los tipos de transporte (Portacontenedores, Grúa…) ya van traducidos en la propia web. Los productos de almacén y las operativas llevan el
-- nombre que tú les pones, así que cada uno se traduce una vez (catalán, inglés, francés) y vale para todas las ofertas.
-- Solo administradores y cuentas con la pestaña Comercial. Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
create table if not exists public.crm_traducciones (
  clave text primary key,                 -- el nombre en castellano, en minúsculas y sin tildes
  texto text not null,                    -- el nombre tal como está escrito
  ca text,
  en text,
  fr text,
  updated_at timestamptz not null default now(),
  updated_by text
);

alter table public.crm_traducciones enable row level security;
drop policy if exists crm_traducciones_select on public.crm_traducciones;
drop policy if exists crm_traducciones_insert on public.crm_traducciones;
drop policy if exists crm_traducciones_update on public.crm_traducciones;
drop policy if exists crm_traducciones_delete on public.crm_traducciones;
create policy crm_traducciones_select on public.crm_traducciones for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_traducciones_insert on public.crm_traducciones for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_traducciones_update on public.crm_traducciones for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_traducciones_delete on public.crm_traducciones for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));

notify pgrst, 'reload schema';

-- Comprobación: debe salir 1 fila
select table_name from information_schema.tables where table_schema = 'public' and table_name = 'crm_traducciones';

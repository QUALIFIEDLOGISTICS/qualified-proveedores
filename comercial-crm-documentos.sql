-- ============================================================
-- QUALIFIED PROVEEDORES — Comercial → CRM → Documentos
-- Sitio para guardar PDF y otros documentos (por ejemplo, tarifas de la competencia para guiarse).
-- Solo administradores y cuentas con la pestaña Comercial. Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

-- 1) Lista de documentos (el archivo en sí va al almacenamiento, carpeta «comercial»)
create table if not exists public.crm_documentos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  nombre text not null,
  archivo text,
  categoria text not null default 'competencia' check (categoria in ('competencia', 'cliente', 'contrato', 'otro')),
  empresa text,
  notas text,
  storage_path text not null,
  tipo text,
  tamano bigint
);
create index if not exists crm_documentos_fecha_idx on public.crm_documentos (created_at desc);

alter table public.crm_documentos enable row level security;

create policy crm_documentos_select on public.crm_documentos for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_documentos_insert on public.crm_documentos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_documentos_update on public.crm_documentos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
create policy crm_documentos_delete on public.crm_documentos for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));

-- 2) Permiso para subir y ver archivos de la carpeta «comercial» del almacenamiento (qualified-docs)
create or replace function public.can_access_docs_folder(folder text)
returns boolean
language sql
security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles p where p.id = auth.uid() and (
      p.is_admin
      or (folder = 'attachments' and p.allowed_tabs ?| array['clientes','citas','documentos'])
      or (folder = 'fichajes' and (p.allowed_tabs ?| array['fichajes'] or p.driver_id is not null))
      or (folder = 'deca' and p.allowed_tabs ?| array['trafico'])
      or (folder = 'logos' and p.allowed_tabs ?| array['administracion','clientes','citas','documentos','trafico','autonomos','comercial'])
      or (folder = 'comercial' and p.allowed_tabs ?| array['comercial'])
      or folder not in ('attachments','fichajes','deca','logos','comercial')
    )
  );
$$;

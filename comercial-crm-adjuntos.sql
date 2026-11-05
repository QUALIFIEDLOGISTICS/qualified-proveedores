-- ============================================================
-- QUALIFIED PROVEEDORES — Comercial → CRM → Documentos de cada cotización
-- Carpeta de documentos dentro de cada cotización (botón «Documentos», arriba a la derecha).
-- Los PDF e imágenes marcados «Con la oferta» se añaden al final del PDF cuando se genera la oferta,
-- y la oferta generada se guarda sola en la carpeta.
-- Los archivos van al almacenamiento (carpeta «comercial», que ya existe); aquí solo se apunta la lista.
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.crm_oportunidad_docs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  oportunidad_id uuid not null references public.crm_oportunidades(id) on delete cascade,
  nombre text not null,
  archivo text,
  storage_path text not null,
  tipo text,
  tamano bigint,
  origen text not null default 'subido' check (origen in ('subido', 'oferta')),
  incluir boolean not null default false
);
create index if not exists crm_oportunidad_docs_opp_idx on public.crm_oportunidad_docs (oportunidad_id, created_at);

alter table public.crm_oportunidad_docs enable row level security;

drop policy if exists crm_oportunidad_docs_select on public.crm_oportunidad_docs;
create policy crm_oportunidad_docs_select on public.crm_oportunidad_docs for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
drop policy if exists crm_oportunidad_docs_insert on public.crm_oportunidad_docs;
create policy crm_oportunidad_docs_insert on public.crm_oportunidad_docs for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
drop policy if exists crm_oportunidad_docs_update on public.crm_oportunidad_docs;
create policy crm_oportunidad_docs_update on public.crm_oportunidad_docs for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));
drop policy if exists crm_oportunidad_docs_delete on public.crm_oportunidad_docs;
create policy crm_oportunidad_docs_delete on public.crm_oportunidad_docs for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['comercial'])));

notify pgrst, 'reload schema';

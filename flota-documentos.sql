-- ============================================================
-- QUALIFIED PROVEEDORES — Flota → Documentos de cada vehículo
-- Sitio para guardar dentro de cada tractora o remolque sus documentos
-- (ITV, seguro, tacógrafo, permiso de circulación, ficha técnica…).
-- Los ve y los gestiona quien tenga la pestaña Administración (igual que Flota).
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

-- 1) Lista de documentos (el archivo en sí va al almacenamiento, carpeta «flota»)
create table if not exists public.flota_documentos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  vehiculo_id uuid not null references public.flota(id) on delete cascade,
  nombre text not null,
  archivo text,
  categoria text not null default 'otro' check (categoria in ('itv', 'seguro', 'tacografo', 'permiso', 'ficha', 'otro')),
  storage_path text not null,
  tipo text,
  tamano bigint
);
create index if not exists flota_documentos_vehiculo_idx on public.flota_documentos (vehiculo_id, created_at desc);

alter table public.flota_documentos enable row level security;

drop policy if exists flota_documentos_select on public.flota_documentos;
drop policy if exists flota_documentos_insert on public.flota_documentos;
drop policy if exists flota_documentos_update on public.flota_documentos;
drop policy if exists flota_documentos_delete on public.flota_documentos;

create policy flota_documentos_select on public.flota_documentos for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion'])));
create policy flota_documentos_insert on public.flota_documentos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion'])));
create policy flota_documentos_update on public.flota_documentos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion'])));
create policy flota_documentos_delete on public.flota_documentos for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['administracion'])));

-- 2) Permiso para subir y ver archivos de la carpeta «flota» del almacenamiento (qualified-docs)
--    (se mantiene todo lo anterior y se añade «flota»)
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
      or (folder = 'flota' and p.allowed_tabs ?| array['administracion'])
      or folder not in ('attachments','fichajes','deca','logos','comercial','flota')
    )
  );
$$;

notify pgrst, 'reload schema';

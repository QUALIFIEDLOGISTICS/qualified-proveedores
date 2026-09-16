-- ============================================================
-- QUALIFIED PROVEEDORES — DeCA (Documento electrónico de Control
-- Administrativo), obligatorio para transporte de mercancías por
-- carretera. El PDF con su QR se genera en el navegador y se
-- guarda en el bucket qualified-docs, carpeta "deca/".
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, después de los anteriores.
-- ============================================================

create table public.deca_documents (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  cargador_nombre text not null,
  cargador_nif text not null,
  cargador_domicilio text,
  transportista_nombre text not null,
  transportista_nif text not null,
  origen text not null,
  destino text not null,
  mercancia_naturaleza text not null,
  mercancia_peso text not null,
  autorizacion_especial text,
  fecha_transporte date not null,
  matricula text not null,
  observaciones text,
  pdf_storage_path text,
  pdf_url text
);

alter table public.deca_documents enable row level security;

create policy deca_documents_select on public.deca_documents for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy deca_documents_insert on public.deca_documents for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy deca_documents_update on public.deca_documents for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy deca_documents_delete on public.deca_documents for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);

-- ---------- STORAGE: carpeta "deca/" exige la pestaña "trafico" ----------
-- (hasta ahora cualquier carpeta que no fuera "attachments" o "fichajes"
-- quedaba abierta a cualquier autenticado por el catch-all de esta
-- función — se añade "deca" explícitamente y se saca del catch-all).
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
      or folder not in ('attachments','fichajes','deca')
    )
  );
$$;

-- ============================================================
-- QUALIFIED PROVEEDORES — logo del contacto, guardado en el
-- bucket qualified-docs, carpeta "logos/".
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================

alter table public.contactos add column if not exists logo_storage_path text;

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
      or (folder = 'logos' and p.allowed_tabs ?| array['administracion','clientes','citas','documentos','trafico','autonomos'])
      or folder not in ('attachments','fichajes','deca','logos')
    )
  );
$$;

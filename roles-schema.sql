-- ============================================================
-- QUALIFIED PROVEEDORES — roles y visibilidad de módulos
-- Instrucciones: Supabase → SQL Editor → pega este archivo
-- ENTERO → Run. Se ejecuta una sola vez, DESPUÉS de schema.sql.
-- ============================================================

-- ---------- PERFILES (rol + pestañas visibles por usuario) ----------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  is_admin boolean not null default false,
  allowed_tabs jsonb not null default '["clientes","citas","documentos","trafico","autonomos"]'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy profiles_select on public.profiles for select
  using (auth.role() = 'authenticated');

create policy profiles_update on public.profiles for update
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin));

create policy profiles_insert on public.profiles for insert
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin));

create policy profiles_delete on public.profiles for delete
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin));

-- Crea automáticamente un perfil (acceso completo por defecto) cada vez
-- que se da de alta una cuenta nueva en Authentication → Users.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Crea también un perfil para cada cuenta que ya existiera antes de
-- ejecutar este script (para que no se quede sin fila en "profiles").
insert into public.profiles (id, email)
select id, email from auth.users
on conflict (id) do nothing;

-- ⚠️ IMPORTANTE: marca tu propia cuenta como administrador (cambia el
-- correo por el tuyo) — si no, no verás el apartado de Administración.
-- update public.profiles set is_admin = true where email = 'TU_CORREO_AQUI';

-- ============================================================
-- RLS de las tablas existentes: se sustituye "cualquier autenticado,
-- acceso total" por una comprobación de módulo contra profiles.
-- Los administradores siempre tienen acceso completo.
-- ============================================================
do $$
declare t text;
begin
  -- Grupo ALMACENES: exige tener al menos una de estas pestañas.
  for t in select unnest(array[
    'clients','client_warehouses','pallets','movements',
    'appointments','unscheduled_trucks','attachments','warehouse_schedules'
  ]) loop
    execute format('drop policy if exists %I on public.%I', t||'_select', t);
    execute format('drop policy if exists %I on public.%I', t||'_insert', t);
    execute format('drop policy if exists %I on public.%I', t||'_update', t);
    execute format('drop policy if exists %I on public.%I', t||'_delete', t);
    execute format($f$
      create policy %1$I on public.%2$I for select using (
        exists (select 1 from public.profiles p where p.id = auth.uid()
          and (p.is_admin or p.allowed_tabs ?| array['clientes','citas','documentos']))
      )$f$, t||'_select', t);
    execute format($f$
      create policy %1$I on public.%2$I for insert with check (
        exists (select 1 from public.profiles p where p.id = auth.uid()
          and (p.is_admin or p.allowed_tabs ?| array['clientes','citas','documentos']))
      )$f$, t||'_insert', t);
    execute format($f$
      create policy %1$I on public.%2$I for update using (
        exists (select 1 from public.profiles p where p.id = auth.uid()
          and (p.is_admin or p.allowed_tabs ?| array['clientes','citas','documentos']))
      )$f$, t||'_update', t);
    execute format($f$
      create policy %1$I on public.%2$I for delete using (
        exists (select 1 from public.profiles p where p.id = auth.uid()
          and (p.is_admin or p.allowed_tabs ?| array['clientes','citas','documentos']))
      )$f$, t||'_delete', t);
  end loop;

  -- Grupo AUTÓNOMOS: exige tener "trafico" o "autonomos".
  for t in select unnest(array[
    'companies','drivers','driver_rates','weekly_entries','fuel_entries',
    'supplement_entries','expense_entries','indexation_entries','daily_entries'
  ]) loop
    execute format('drop policy if exists %I on public.%I', t||'_select', t);
    execute format('drop policy if exists %I on public.%I', t||'_insert', t);
    execute format('drop policy if exists %I on public.%I', t||'_update', t);
    execute format('drop policy if exists %I on public.%I', t||'_delete', t);
    execute format($f$
      create policy %1$I on public.%2$I for select using (
        exists (select 1 from public.profiles p where p.id = auth.uid()
          and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
      )$f$, t||'_select', t);
    execute format($f$
      create policy %1$I on public.%2$I for insert with check (
        exists (select 1 from public.profiles p where p.id = auth.uid()
          and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
      )$f$, t||'_insert', t);
    execute format($f$
      create policy %1$I on public.%2$I for update using (
        exists (select 1 from public.profiles p where p.id = auth.uid()
          and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
      )$f$, t||'_update', t);
    execute format($f$
      create policy %1$I on public.%2$I for delete using (
        exists (select 1 from public.profiles p where p.id = auth.uid()
          and (p.is_admin or p.allowed_tabs ?| array['trafico','autonomos']))
      )$f$, t||'_delete', t);
  end loop;
end $$;

-- 'warehouses' se deja tal cual (abierta a cualquier autenticado) — es
-- solo la lista fija de 3 almacenes, sin dato sensible que proteger.

-- Storage (qualified-docs): los PDF de citas/documentos viven bajo
-- "attachments/" (grupo Almacenes) y las fotos de tacógrafo bajo
-- "fichajes/" (grupo Autónomos) — cada carpeta exige el grupo que le
-- corresponde, igual que las tablas.
drop policy if exists "qualified_docs_select" on storage.objects;
drop policy if exists "qualified_docs_insert" on storage.objects;
drop policy if exists "qualified_docs_update" on storage.objects;
drop policy if exists "qualified_docs_delete" on storage.objects;

create or replace function public.can_access_docs_folder(folder text)
returns boolean
language sql
security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles p where p.id = auth.uid() and (
      p.is_admin
      or (folder = 'attachments' and p.allowed_tabs ?| array['clientes','citas','documentos'])
      or (folder = 'fichajes' and p.allowed_tabs ?| array['trafico','autonomos'])
      or folder not in ('attachments','fichajes')
    )
  );
$$;

create policy "qualified_docs_select" on storage.objects for select using (
  bucket_id = 'qualified-docs' and public.can_access_docs_folder((storage.foldername(name))[1])
);
create policy "qualified_docs_insert" on storage.objects for insert with check (
  bucket_id = 'qualified-docs' and public.can_access_docs_folder((storage.foldername(name))[1])
);
create policy "qualified_docs_update" on storage.objects for update using (
  bucket_id = 'qualified-docs' and public.can_access_docs_folder((storage.foldername(name))[1])
);
create policy "qualified_docs_delete" on storage.objects for delete using (
  bucket_id = 'qualified-docs' and public.can_access_docs_folder((storage.foldername(name))[1])
);

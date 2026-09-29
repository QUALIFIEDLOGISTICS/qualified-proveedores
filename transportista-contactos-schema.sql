-- ============================================================
-- QUALIFIED PROVEEDORES — Transporte → un transportista puede tener varios
-- contactos (empresas grandes con una persona por tema: rutas nacionales,
-- internacional, facturación...), en vez de uno solo pegado al contacto.
-- Solo administradores y cuentas con la pestaña Tráfico los ven y los editan.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.transportista_contactos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  contacto_id uuid not null references public.contactos(id) on delete cascade,
  nombre text,
  apellidos text,
  cargo text,
  ambito text,
  email text,
  telefono text
);
create index if not exists transportista_contactos_contacto_idx on public.transportista_contactos (contacto_id);
alter table public.transportista_contactos enable row level security;

drop policy if exists transportista_contactos_select on public.transportista_contactos;
drop policy if exists transportista_contactos_insert on public.transportista_contactos;
drop policy if exists transportista_contactos_update on public.transportista_contactos;
drop policy if exists transportista_contactos_delete on public.transportista_contactos;

create policy transportista_contactos_select on public.transportista_contactos for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy transportista_contactos_insert on public.transportista_contactos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy transportista_contactos_update on public.transportista_contactos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy transportista_contactos_delete on public.transportista_contactos for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);

-- Migra el contacto único que ya hubiera apuntado en la propia ficha del
-- transportista (nombre/apellidos/cargo/correo/teléfono de transporte) a la
-- nueva tabla, para no perder lo que ya había.
insert into public.transportista_contactos (contacto_id, nombre, apellidos, cargo, email, telefono)
select id, nombre_transportista, apellidos_transportista, cargo_transportista, email_transportista, telefono_transportista
from public.contactos
where nombre_transportista is not null or apellidos_transportista is not null or cargo_transportista is not null
   or email_transportista is not null or telefono_transportista is not null;

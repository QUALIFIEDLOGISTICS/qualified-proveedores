-- ============================================================
-- QUALIFIED PROVEEDORES — Historial de cambios de permisos en
-- Gestión de Permisos (quién cambió qué a cada usuario y cuándo).
-- Solo lo ven y lo escriben los administradores. La pantalla funciona
-- sin esto; sin él, solo falta el historial de la derecha.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.profile_historial (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  usuario text,
  resumen text not null
);
alter table public.profile_historial enable row level security;

drop policy if exists profile_historial_select on public.profile_historial;
drop policy if exists profile_historial_insert on public.profile_historial;

create policy profile_historial_select on public.profile_historial for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
);
create policy profile_historial_insert on public.profile_historial for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
);

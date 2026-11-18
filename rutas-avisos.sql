-- ============================================================
-- QUALIFIED PROVEEDORES — Rutas · «Avisar seleccionados» (fase 2): registro de los avisos de carga
-- Solo CREA dos tablas nuevas (no toca ninguna existente). Se puede ejecutar más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
--
--   trafico_avisos                  Un aviso = una carga que se ofrece: ruta, fecha de carga, servicio, vehículo, mercancía, observaciones,
--                                   el texto enviado, quién lo hizo y cuándo.
--   trafico_aviso_destinatarios     Los transportistas avisados de ese aviso, por qué canal (WhatsApp / correo) y cómo va:
--                                   avisado → respondió → precio ofertado → adjudicado (con el precio que ofreció, si lo hay).
-- Lo ve y lo edita quien tiene el módulo Transporte (igual que Rutas).
-- ============================================================

create table if not exists public.trafico_avisos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  origen text,
  destino text,
  fecha_carga date,
  servicio text,
  vehiculo text,
  mercancia text,
  observaciones text,
  mensaje text
);
create index if not exists trafico_avisos_fecha_idx on public.trafico_avisos (created_at desc);

create table if not exists public.trafico_aviso_destinatarios (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  aviso_id uuid not null references public.trafico_avisos(id) on delete cascade,
  contacto_id uuid references public.contactos(id) on delete set null,
  contacto_nombre text,
  canal text not null default 'whatsapp' check (canal in ('whatsapp', 'email', 'ambos')),
  estado text not null default 'avisado' check (estado in ('avisado', 'respondio', 'ofertado', 'adjudicado')),
  precio_ofertado numeric,
  updated_at timestamptz not null default now()
);
create index if not exists trafico_aviso_dest_aviso_idx on public.trafico_aviso_destinatarios (aviso_id);

alter table public.trafico_avisos enable row level security;
alter table public.trafico_aviso_destinatarios enable row level security;

drop policy if exists trafico_avisos_select on public.trafico_avisos;
drop policy if exists trafico_avisos_insert on public.trafico_avisos;
drop policy if exists trafico_avisos_update on public.trafico_avisos;
create policy trafico_avisos_select on public.trafico_avisos for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy trafico_avisos_insert on public.trafico_avisos for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy trafico_avisos_update on public.trafico_avisos for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);

drop policy if exists trafico_aviso_dest_select on public.trafico_aviso_destinatarios;
drop policy if exists trafico_aviso_dest_insert on public.trafico_aviso_destinatarios;
drop policy if exists trafico_aviso_dest_update on public.trafico_aviso_destinatarios;
create policy trafico_aviso_dest_select on public.trafico_aviso_destinatarios for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy trafico_aviso_dest_insert on public.trafico_aviso_destinatarios for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy trafico_aviso_dest_update on public.trafico_aviso_destinatarios for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);

notify pgrst, 'reload schema';

-- Comprobación: deben salir 2 filas
select table_name from information_schema.tables
where table_schema = 'public' and table_name in ('trafico_avisos', 'trafico_aviso_destinatarios') order by 1;

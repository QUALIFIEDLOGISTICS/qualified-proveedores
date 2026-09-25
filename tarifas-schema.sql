-- ============================================================
-- QUALIFIED PROVEEDORES — Tráfico → Tarifas: histórico de precios
-- que se pasan a cada cliente, por zona de origen y destino
-- (país + 2 primeras cifras del CP: ES08, FR13…), FTL o LTL (metros).
-- Cada fila es una tarifa con su fecha; la vigente de una ruta es la
-- más reciente. Pueden verlas y editarlas administradores y cuentas
-- con la pestaña Tráfico.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.tarifas (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  fecha date not null,
  cliente_id uuid not null references public.contactos(id) on delete restrict,
  origen_zona text not null,
  origen_cp text,
  destino_zona text not null,
  destino_cp text,
  tipo text not null check (tipo in ('FTL', 'LTL')),
  metros numeric(4,1) check (metros is null or (metros > 0 and metros <= 13.6)),
  precio numeric(10,2) not null check (precio >= 0),
  observaciones text
);
create index if not exists tarifas_ruta_idx on public.tarifas (origen_zona, destino_zona);
create index if not exists tarifas_cliente_idx on public.tarifas (cliente_id);
alter table public.tarifas enable row level security;

drop policy if exists tarifas_select on public.tarifas;
drop policy if exists tarifas_insert on public.tarifas;
drop policy if exists tarifas_update on public.tarifas;
drop policy if exists tarifas_delete on public.tarifas;

create policy tarifas_select on public.tarifas for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy tarifas_insert on public.tarifas for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy tarifas_update on public.tarifas for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);
create policy tarifas_delete on public.tarifas for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['trafico']))
);

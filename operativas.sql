-- ============================================================
-- QUALIFIED PROVEEDORES — Comercial → Operativas de un cliente
-- Una operativa es un paquete de servicios con precio cerrado
-- (p. ej. "Acarreo puerto + Manipulación mercancía + Transporte
-- final"), desglosado por apartados. El total es la suma de los
-- apartados. Cada fila tiene su fecha de vigencia: al cambiar el
-- precio se añade una nueva con el mismo nombre y la anterior pasa
-- al histórico. Pueden verlas y editarlas administradores y cuentas
-- con la pestaña Comercial.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.operativas (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  cliente_id uuid not null references public.contactos(id) on delete restrict,
  nombre text not null,
  fecha date not null,
  apartados jsonb not null default '[]'::jsonb,
  precio_total numeric(12,2) not null check (precio_total >= 0),
  observaciones text
);
create index if not exists operativas_cliente_idx on public.operativas (cliente_id);
alter table public.operativas enable row level security;

drop policy if exists operativas_select on public.operativas;
drop policy if exists operativas_insert on public.operativas;
drop policy if exists operativas_update on public.operativas;
drop policy if exists operativas_delete on public.operativas;

create policy operativas_select on public.operativas for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['comercial']))
);
create policy operativas_insert on public.operativas for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['comercial']))
);
create policy operativas_update on public.operativas for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['comercial']))
);
create policy operativas_delete on public.operativas for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid()
    and (p.is_admin or p.allowed_tabs ?| array['comercial']))
);

notify pgrst, 'reload schema';

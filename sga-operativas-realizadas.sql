-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Operativas realizadas
-- Cada vez que a un cliente se le hace una operativa (un servicio con precio cerrado de los de Comercial → Tarifas Almacén →
-- Operativas) se anota aquí con su fecha y sus extras por cantidad. Salen en el Resumen mensual del cliente, en «A facturar».
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================

create table if not exists public.sga_operativas_realizadas (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  cliente_id uuid not null references public.contactos(id) on delete restrict,
  operativa_id uuid references public.operativas(id) on delete set null,
  nombre text not null,
  fecha date not null,
  apartados jsonb not null default '[]'::jsonb,   -- copia de los apartados con su precio de ese día (y la cantidad de los extras)
  importe numeric(12,2) not null default 0 check (importe >= 0),
  observaciones text,
  estado text not null default 'activa' check (estado in ('activa', 'anulada')),
  anulada_at timestamptz
);
create index if not exists sga_operativas_realizadas_cliente_idx on public.sga_operativas_realizadas (cliente_id, fecha);
alter table public.sga_operativas_realizadas enable row level security;

drop policy if exists sga_operativas_realizadas_select on public.sga_operativas_realizadas;
drop policy if exists sga_operativas_realizadas_insert on public.sga_operativas_realizadas;
drop policy if exists sga_operativas_realizadas_update on public.sga_operativas_realizadas;
create policy sga_operativas_realizadas_select on public.sga_operativas_realizadas for select using (public.sga_permiso('stock', 'almacenconfig'));
create policy sga_operativas_realizadas_insert on public.sga_operativas_realizadas for insert with check (public.sga_permiso('stock'));
create policy sga_operativas_realizadas_update on public.sga_operativas_realizadas for update using (public.sga_permiso('stock'));

-- Quien trabaja en el SGA (pestaña Stock) también puede LEER las operativas de Comercial para elegirlas (no puede cambiarlas)
drop policy if exists operativas_select_stock on public.operativas;
create policy operativas_select_stock on public.operativas for select using (public.sga_permiso('stock', 'almacenconfig'));

notify pgrst, 'reload schema';

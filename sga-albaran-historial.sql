-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Historial de cambios de cada albarán (entradas y salidas)
-- Quién creó, editó, confirmó o anuló un albarán, cuándo y qué cambió. Se ve a la derecha al abrir una entrada o una salida.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
create table if not exists public.sga_albaran_historial (
  id uuid primary key default gen_random_uuid(),
  albaran_id uuid not null references public.sga_albaranes(id) on delete cascade,
  created_at timestamptz not null default now(),
  usuario text,
  resumen text not null
);
create index if not exists sga_albaran_historial_albaran_idx on public.sga_albaran_historial (albaran_id, created_at desc);
alter table public.sga_albaran_historial enable row level security;

drop policy if exists sga_albaran_historial_select on public.sga_albaran_historial;
drop policy if exists sga_albaran_historial_insert on public.sga_albaran_historial;
create policy sga_albaran_historial_select on public.sga_albaran_historial for select using (public.sga_permiso('stock', 'almacenconfig'));
create policy sga_albaran_historial_insert on public.sga_albaran_historial for insert with check (public.sga_permiso('stock'));

notify pgrst, 'reload schema';

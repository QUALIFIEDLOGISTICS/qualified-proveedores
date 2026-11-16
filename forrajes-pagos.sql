-- ============================================================
-- QUALIFIED PROVEEDORES — Forrajes: pestaña «Pagos» (reparto del beneficio entre los socios y pagos realizados)
-- Tablas:
--   forraje_socios      → quién reparte y con qué porcentaje (p. ej. 50 / 25 / 25)
--   forraje_pagos       → cada pago hecho a un socio (fecha, importe y concepto); se descuenta de lo que le corresponde
--   forraje_ajustes_mes → corrección opcional del beneficio de un mes (suma o resta a lo que salen de los viajes)
-- Es una pestaña SOLO PARA ADMINISTRADORES: las tres tablas solo las lee y escribe un administrador.
-- Es seguro ejecutarlo más de una vez y no toca los viajes.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
create table if not exists public.forraje_socios (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  nombre text not null,
  porcentaje numeric(6,3) not null check (porcentaje >= 0 and porcentaje <= 100),
  orden integer not null default 0
);

create table if not exists public.forraje_pagos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  socio_id uuid not null references public.forraje_socios(id) on delete cascade,
  fecha date not null,
  importe numeric(12,2) not null,   -- positivo = pago al socio; una corrección puede ir en negativo
  concepto text
);
create index if not exists forraje_pagos_socio_idx on public.forraje_pagos (socio_id, fecha desc);

create table if not exists public.forraje_ajustes_mes (
  mes text primary key check (mes ~ '^[0-9]{4}-[0-9]{2}$'),   -- 2025-03
  importe numeric(12,2) not null default 0,
  updated_at timestamptz not null default now()
);

-- Seguridad: solo administradores
do $$
declare t text;
begin
  foreach t in array array['forraje_socios', 'forraje_pagos', 'forraje_ajustes_mes'] loop
    execute format('alter table public.%1$s enable row level security', t);
    execute format('drop policy if exists %1$s_admin on public.%1$s', t);
    execute format('create policy %1$s_admin on public.%1$s for all using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)) with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin))', t);
  end loop;
end $$;

notify pgrst, 'reload schema';

-- Comprobación: debe salir 0 en las tres (todavía no hay nada)
select (select count(*) from public.forraje_socios) as socios, (select count(*) from public.forraje_pagos) as pagos, (select count(*) from public.forraje_ajustes_mes) as ajustes;

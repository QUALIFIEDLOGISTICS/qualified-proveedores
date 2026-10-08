-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Catálogo de artículos por cliente (como la hoja «BASE DE DATOS» del Excel)
-- Cada cliente tiene sus artículos: producto, referencia, bultos por módulo, metros lineales, peso, medidas…
-- Las entradas y salidas se hacen eligiendo el artículo, y se guardan los módulos Y los bultos (se puede
-- cobrar «por bulto»). También actualiza las dos funciones de confirmar entrada y salida para guardar el artículo
-- y los bultos.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.sga_articulos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  cliente_id uuid not null references public.contactos(id),
  nombre text not null,                                   -- «Producto»
  referencia text,                                        -- «Referencia» / modelo
  producto_id text references public.almacenaje_productos(id),  -- tipo de carga habitual (Palet, Bobina…)
  zona_id uuid references public.sga_zonas(id),           -- nave / zona habitual
  bultos_por_unidad numeric(12,2) not null default 1 check (bultos_por_unidad > 0),   -- bultos/cajas por módulo
  metros_lineales numeric(12,2),
  peso numeric(12,2),
  medidas text,                                           -- «Información (largo × ancho × alto)»
  finalidad text,
  archived boolean not null default false
);
create unique index if not exists sga_articulos_unico on public.sga_articulos (cliente_id, lower(coalesce(nullif(referencia, ''), nombre)));
create index if not exists sga_articulos_cliente_idx on public.sga_articulos (cliente_id);
alter table public.sga_articulos enable row level security;
drop policy if exists sga_articulos_select on public.sga_articulos;
drop policy if exists sga_articulos_insert on public.sga_articulos;
drop policy if exists sga_articulos_update on public.sga_articulos;
create policy sga_articulos_select on public.sga_articulos for select using (public.sga_permiso('stock', 'almacenconfig', 'clientes', 'citas'));
create policy sga_articulos_insert on public.sga_articulos for insert with check (public.sga_permiso('stock', 'almacenconfig'));
create policy sga_articulos_update on public.sga_articulos for update using (public.sga_permiso('stock', 'almacenconfig'));

alter table public.sga_partidas add column if not exists articulo_id uuid references public.sga_articulos(id);
alter table public.sga_partidas add column if not exists bultos numeric(12,2);
alter table public.sga_movimientos add column if not exists bultos numeric(12,2);   -- + entra, − sale

-- ---------- Confirmar entrada (ahora con artículo y bultos) ----------
create or replace function public.sga_confirmar_entrada(p jsonb) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  a jsonb := p->'albaran';
  v_albaran uuid;
  v_partida uuid;
  v_fecha date := (a->>'fecha')::date;
  v_tipo text := coalesce(nullif(a->>'tipo', ''), 'entrada');
  r jsonb;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para registrar entradas.';
  end if;
  if jsonb_array_length(coalesce(p->'partidas', '[]'::jsonb)) = 0 then
    raise exception 'La entrada no tiene mercancía.';
  end if;

  insert into public.sga_albaranes (created_by, tipo, cliente_id, warehouse_id, fecha, referencia, modalidad, transportista, matricula, observaciones, estado, confirmado_at)
  values (a->>'created_by', v_tipo, (a->>'cliente_id')::uuid, a->>'warehouse_id', v_fecha,
          nullif(a->>'referencia', ''), coalesce(nullif(a->>'modalidad', ''), 'palet'),
          nullif(a->>'transportista', ''), nullif(a->>'matricula', ''), nullif(a->>'observaciones', ''), 'confirmado', now())
  returning id into v_albaran;

  for r in select value from jsonb_array_elements(p->'partidas') loop
    insert into public.sga_partidas (cliente_id, warehouse_id, zona_id, ubicacion_id, producto_id, referencia, descripcion, lote, codigo,
                                     cantidad_inicial, cantidad_actual, fecha_entrada, albaran_entrada_id, atributos, articulo_id, bultos)
    values ((a->>'cliente_id')::uuid, a->>'warehouse_id', nullif(r->>'zona_id', '')::uuid, nullif(r->>'ubicacion_id', '')::uuid, r->>'producto_id',
            nullif(r->>'referencia', ''), nullif(r->>'descripcion', ''), nullif(r->>'lote', ''), nullif(r->>'codigo', ''),
            (r->>'cantidad')::int, (r->>'cantidad')::int, v_fecha, v_albaran, coalesce(r->'atributos', '{}'::jsonb),
            nullif(r->>'articulo_id', '')::uuid, nullif(r->>'bultos', '')::numeric)
    returning id into v_partida;

    insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, bultos)
    values (a->>'created_by', v_partida, v_albaran, v_tipo, (r->>'cantidad')::int, v_fecha, nullif(r->>'bultos', '')::numeric);
  end loop;

  for r in select value from jsonb_array_elements(coalesce(p->'servicios', '[]'::jsonb)) loop
    insert into public.sga_servicios (albaran_id, producto_id, cantidad, nota)
    values (v_albaran, r->>'producto_id', (r->>'cantidad')::numeric, nullif(r->>'nota', ''));
  end loop;

  for r in select value from jsonb_array_elements(coalesce(p->'cobros', '[]'::jsonb)) loop
    insert into public.sga_cobros (cliente_id, albaran_id, fecha, periodo, origen, producto_id, subtipo, cantidad, precio, importe, tarifa_id, nota)
    values ((a->>'cliente_id')::uuid, v_albaran, v_fecha, to_char(v_fecha, 'YYYY-MM'), r->>'origen', r->>'producto_id', nullif(r->>'subtipo', ''),
            (r->>'cantidad')::numeric, (r->>'precio')::numeric, (r->>'importe')::numeric, nullif(r->>'tarifa_id', '')::uuid, nullif(r->>'nota', ''));
  end loop;

  return v_albaran;
end $$;

-- ---------- Confirmar salida (ahora con bultos) ----------
create or replace function public.sga_confirmar_salida(p jsonb) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  a jsonb := p->'albaran';
  v_albaran uuid;
  v_fecha date := (a->>'fecha')::date;
  v_cli uuid := (a->>'cliente_id')::uuid;
  v_actual int;
  v_cant int;
  v_bultos numeric;
  r jsonb;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para registrar salidas.';
  end if;
  if jsonb_array_length(coalesce(p->'salidas', '[]'::jsonb)) = 0 then
    raise exception 'La salida no tiene mercancía.';
  end if;

  insert into public.sga_albaranes (created_by, tipo, cliente_id, warehouse_id, fecha, referencia, modalidad, transportista, matricula, observaciones, estado, confirmado_at)
  values (a->>'created_by', 'salida', v_cli, a->>'warehouse_id', v_fecha,
          nullif(a->>'referencia', ''), coalesce(nullif(a->>'modalidad', ''), 'palet'),
          nullif(a->>'transportista', ''), nullif(a->>'matricula', ''), nullif(a->>'observaciones', ''), 'confirmado', now())
  returning id into v_albaran;

  for r in select value from jsonb_array_elements(p->'salidas') loop
    v_cant := (r->>'cantidad')::int;
    v_bultos := nullif(r->>'bultos', '')::numeric;
    select cantidad_actual into v_actual from public.sga_partidas
      where id = (r->>'partida_id')::uuid and cliente_id = v_cli for update;
    if not found then
      raise exception 'Una de las partidas ya no existe o no es de este cliente. Recarga la pantalla.';
    end if;
    if v_actual < v_cant then
      raise exception 'Ya no queda stock suficiente en una partida (quedan %, se pedían %). Recarga la pantalla.', v_actual, v_cant;
    end if;
    update public.sga_partidas
      set cantidad_actual = cantidad_actual - v_cant,
          estado = case when cantidad_actual - v_cant = 0 then 'agotada' else estado end
      where id = (r->>'partida_id')::uuid;
    insert into public.sga_movimientos (created_by, partida_id, albaran_id, tipo, cantidad, fecha, fifo_saltado, bultos)
    values (a->>'created_by', (r->>'partida_id')::uuid, v_albaran, 'salida', -v_cant, v_fecha, coalesce((r->>'fifo_saltado')::boolean, false),
            case when v_bultos is null then null else -v_bultos end);
  end loop;

  for r in select value from jsonb_array_elements(coalesce(p->'servicios', '[]'::jsonb)) loop
    insert into public.sga_servicios (albaran_id, producto_id, cantidad, nota)
    values (v_albaran, r->>'producto_id', (r->>'cantidad')::numeric, nullif(r->>'nota', ''));
  end loop;

  for r in select value from jsonb_array_elements(coalesce(p->'cobros', '[]'::jsonb)) loop
    insert into public.sga_cobros (cliente_id, albaran_id, fecha, periodo, origen, producto_id, subtipo, cantidad, precio, importe, tarifa_id, nota)
    values (v_cli, v_albaran, v_fecha, to_char(v_fecha, 'YYYY-MM'), r->>'origen', r->>'producto_id', nullif(r->>'subtipo', ''),
            (r->>'cantidad')::numeric, (r->>'precio')::numeric, (r->>'importe')::numeric, nullif(r->>'tarifa_id', '')::uuid, nullif(r->>'nota', ''));
  end loop;

  return v_albaran;
end $$;

notify pgrst, 'reload schema';

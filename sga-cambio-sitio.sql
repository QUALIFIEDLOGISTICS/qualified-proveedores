-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Cambio de almacén o de ubicación de la mercancía (Ajustes de stock)
-- Para cuando un cliente reorganiza su material (p. ej. lo pasa de un almacén a otro): solo cambia DÓNDE está cada partida.
--  · NO crea movimientos, NO crea albaranes y NO genera cobros: la cantidad y la fecha de recepción de cada partida no cambian.
--  · Queda constancia en una tabla de cambios (quién, cuándo, de dónde a dónde, motivo y qué partidas) y en el historial de los almacenes.
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

create table if not exists public.sga_cambios_sitio (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text,
  cliente_id uuid not null references public.contactos(id),
  fecha date not null,
  motivo text not null,
  warehouse_origen text references public.warehouses(id),
  warehouse_destino text not null references public.warehouses(id),
  partidas integer not null default 0,
  unidades integer not null default 0,
  detalle jsonb not null default '[]'::jsonb      -- por cada partida: dónde estaba y dónde queda
);
create index if not exists sga_cambios_sitio_cliente_idx on public.sga_cambios_sitio (cliente_id, fecha desc);

alter table public.sga_cambios_sitio enable row level security;
drop policy if exists sga_cambios_sitio_select on public.sga_cambios_sitio;
drop policy if exists sga_cambios_sitio_insert on public.sga_cambios_sitio;
create policy sga_cambios_sitio_select on public.sga_cambios_sitio for select using (public.sga_permiso('stock'));
create policy sga_cambios_sitio_insert on public.sga_cambios_sitio for insert with check (public.sga_permiso('stock'));

-- p = { cambio: { created_by, cliente_id, fecha, motivo, warehouse_destino },
--       items: [ { partida_id, zona_id (o null), ubicacion_id (o null) } ] }
create or replace function public.sga_cambiar_sitio(p jsonb) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  c jsonb := p->'cambio';
  v_cli uuid := (c->>'cliente_id')::uuid;
  v_dest text := c->>'warehouse_destino';
  v_fecha date := (c->>'fecha')::date;
  v_id uuid;
  v_n int := 0;
  v_u int := 0;
  v_origs text[] := '{}';
  v_orig text;
  v_det jsonb := '[]'::jsonb;
  r jsonb;
  pt public.sga_partidas%rowtype;
  v_zona uuid;
  v_ubic uuid;
begin
  if not public.sga_permiso('stock') then
    raise exception 'No tienes permiso para cambiar la mercancía de sitio.';
  end if;
  if jsonb_array_length(coalesce(p->'items', '[]'::jsonb)) = 0 then
    raise exception 'No hay nada que cambiar de sitio.';
  end if;
  if nullif(trim(c->>'motivo'), '') is null then
    raise exception 'Indica el motivo del cambio.';
  end if;
  if not exists (select 1 from public.warehouses where id = v_dest) then
    raise exception 'El almacén de destino no existe.';
  end if;

  for r in select value from jsonb_array_elements(p->'items') loop
    select * into pt from public.sga_partidas where id = (r->>'partida_id')::uuid and cliente_id = v_cli for update;
    if not found then
      raise exception 'Una de las partidas ya no existe o no es de este cliente. Recarga la pantalla.';
    end if;
    if pt.estado <> 'activa' or pt.cantidad_actual <= 0 then
      raise exception 'Una de las partidas ya no tiene stock. Recarga la pantalla.';
    end if;
    v_zona := nullif(r->>'zona_id', '')::uuid;
    v_ubic := nullif(r->>'ubicacion_id', '')::uuid;
    if v_zona is not null and not exists (select 1 from public.sga_zonas where id = v_zona and warehouse_id = v_dest and not archived) then
      raise exception 'Una de las zonas elegidas no es del almacén de destino.';
    end if;
    if v_ubic is not null then
      if v_zona is null or not exists (select 1 from public.sga_ubicaciones where id = v_ubic and zona_id = v_zona and not archived) then
        raise exception 'Una de las ubicaciones elegidas no es de su zona.';
      end if;
      if exists (select 1 from public.sga_partidas x where x.ubicacion_id = v_ubic and x.cantidad_actual > 0 and x.id <> pt.id) then
        raise exception 'Una de las ubicaciones elegidas ya está ocupada.';
      end if;
    end if;
    v_det := v_det || jsonb_build_object('partida_id', pt.id, 'cantidad', pt.cantidad_actual,
      'antes', jsonb_build_object('warehouse_id', pt.warehouse_id, 'zona_id', pt.zona_id, 'ubicacion_id', pt.ubicacion_id),
      'despues', jsonb_build_object('warehouse_id', v_dest, 'zona_id', v_zona, 'ubicacion_id', v_ubic));
    v_origs := v_origs || pt.warehouse_id;
    update public.sga_partidas set warehouse_id = v_dest, zona_id = v_zona, ubicacion_id = v_ubic where id = pt.id;
    v_n := v_n + 1; v_u := v_u + pt.cantidad_actual;
  end loop;

  select case when count(distinct x) = 1 then min(x) end into v_orig from unnest(v_origs) x;   -- si venían de varios almacenes no se guarda uno solo

  insert into public.sga_cambios_sitio (created_by, cliente_id, fecha, motivo, warehouse_origen, warehouse_destino, partidas, unidades, detalle)
  values (c->>'created_by', v_cli, v_fecha, trim(c->>'motivo'), v_orig, v_dest, v_n, v_u, v_det)
  returning id into v_id;
  return v_id;
end $$;

notify pgrst, 'reload schema';

-- Comprobación: debe salir la tabla y la función
select 'tabla' as que, count(*)::text as hay from information_schema.tables where table_schema = 'public' and table_name = 'sga_cambios_sitio'
union all
select 'funcion', count(*)::text from pg_proc where proname = 'sga_cambiar_sitio';

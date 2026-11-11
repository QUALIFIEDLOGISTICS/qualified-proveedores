-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · Fase 2: la base de datos comprueba cada cobro contra la tarifa real
-- Hasta ahora el cobro de cada recepción o expedición lo calculaba el navegador y la base de datos guardaba lo que le llegaba. Ahora, cada cobro de
-- movimiento o de servicio que se guarda se comprueba contra la tarifa del cliente: que la tarifa exista y sea de ese cliente y de ese producto,
-- que estuviera en vigor ese día y fuera la más reciente, que el precio sea el suyo y que el importe sea cantidad × precio (o el importe mínimo).
-- Funciona para TODAS las pantallas (recepción, expedición, editar, actividades…): está en la propia tabla de cobros.
-- Tiene tres modos (se cambia desde Almacén → Control Stock SGA → Revisión, o con el UPDATE del final):
--   · aviso   (el que se activa ahora): el cobro se guarda igual y la incidencia queda apuntada para revisarla.
--   · estricto: si un cobro no cuadra, NO se guarda nada (la recepción o expedición entera se rechaza con el motivo).
--   · apagado : no se comprueba nada.
-- Es seguro ejecutarlo más de una vez. No cambia ningún dato existente.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

-- Ajustes del SGA (una fila por ajuste)
create table if not exists public.sga_ajustes (
  clave text primary key,
  valor text not null,
  updated_at timestamptz not null default now(),
  updated_by text
);
insert into public.sga_ajustes (clave, valor) values ('validar_cobros', 'aviso') on conflict (clave) do nothing;
alter table public.sga_ajustes enable row level security;
drop policy if exists sga_ajustes_select on public.sga_ajustes;
drop policy if exists sga_ajustes_update on public.sga_ajustes;
create policy sga_ajustes_select on public.sga_ajustes for select using (public.sga_permiso('stock', 'almacenconfig'));
create policy sga_ajustes_update on public.sga_ajustes for update using (public.sga_permiso('almacenconfig'));

-- Incidencias: cobros que no cuadraban con la tarifa cuando se guardaron (en modo «aviso»)
create table if not exists public.sga_cobros_incidencias (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  usuario uuid default auth.uid(),
  cliente_id uuid references public.contactos(id),
  albaran_id uuid references public.sga_albaranes(id),
  origen text,
  producto_id text,
  subtipo text,
  fecha date,
  cantidad numeric,
  precio numeric,
  importe numeric,
  tarifa_id uuid,
  motivos text not null
);
create index if not exists sga_cobros_incidencias_fecha_idx on public.sga_cobros_incidencias (created_at desc);
alter table public.sga_cobros_incidencias enable row level security;
drop policy if exists sga_cobros_incidencias_select on public.sga_cobros_incidencias;
create policy sga_cobros_incidencias_select on public.sga_cobros_incidencias for select using (public.sga_permiso('stock', 'almacenconfig'));

-- La comprobación (se ejecuta antes de guardar cada cobro de movimiento o de servicio)
create or replace function public.sga_cobro_validar() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_modo text;
  t public.almacenaje_tarifas%rowtype;
  m text[] := array[]::text[];
  v_base numeric;
  v_tol numeric;
  v_nombre text;
begin
  if new.origen not in ('movimiento', 'servicio') then return new; end if;   -- el almacenaje diario, el de m² y lo manual no se tocan
  select valor into v_modo from public.sga_ajustes where clave = 'validar_cobros';
  v_modo := coalesce(v_modo, 'aviso');
  if v_modo = 'apagado' then return new; end if;

  if new.cantidad is null or new.cantidad <= 0 then m := m || 'la cantidad no es mayor que 0'; end if;
  if new.tarifa_id is null then
    m := m || 'el cobro no indica la tarifa que se aplicó';
  else
    select * into t from public.almacenaje_tarifas where id = new.tarifa_id;
    if not found then
      m := m || 'la tarifa indicada no existe';
    else
      if t.cliente_id is distinct from new.cliente_id then m := m || 'la tarifa es de otro cliente'; end if;
      if t.tipo is distinct from new.producto_id then m := m || 'la tarifa es de otro producto'; end if;
      if coalesce(t.subtipo, '') <> coalesce(new.subtipo, '') then m := m || 'el tipo de palet del cobro no es el de la tarifa'; end if;
      if t.fecha > new.fecha then m := m || 'la tarifa todavía no estaba en vigor en la fecha del albarán'; end if;
      if new.precio is null or abs(new.precio - t.precio) > 0.000001 then m := m || format('el precio (%s) no es el de la tarifa (%s)', new.precio, t.precio); end if;
      v_base := round(coalesce(new.cantidad, 0) * t.precio, 2);
      v_tol := 0.01 + 0.005 * t.precio;   -- la cantidad se guarda con 2 decimales (p. ej. bultos 12,333): margen para ese redondeo
      -- vale cantidad × precio o, si la tarifa tiene importe mínimo por albarán, ese mínimo
      if abs(coalesce(new.importe, -1) - v_base) > v_tol and (t.importe_minimo is null or abs(coalesce(new.importe, -1) - t.importe_minimo) > 0.01) then
        m := m || format('el importe (%s) no cuadra con la cantidad por el precio (%s)', new.importe, v_base);
      end if;
      -- tiene que ser la línea de tarifa más reciente en vigor ese día para ese cliente, producto y tipo
      if exists (
        select 1 from public.almacenaje_tarifas t2
        where t2.cliente_id = t.cliente_id and t2.tipo = t.tipo and coalesce(t2.subtipo, '') = coalesce(t.subtipo, '')
          and t2.id <> t.id and t2.fecha <= new.fecha
          and (t2.fecha > t.fecha or (t2.fecha = t.fecha and t2.created_at > t.created_at))
      ) then m := m || 'hay una línea de tarifa más reciente en vigor ese día'; end if;
    end if;
  end if;

  if array_length(m, 1) is null then return new; end if;   -- todo cuadra

  select nombre into v_nombre from public.almacenaje_productos where id = new.producto_id;
  if v_modo = 'estricto' then
    raise exception 'Cobro no válido de «%»: %', coalesce(v_nombre, new.producto_id), array_to_string(m, '; ') using errcode = 'P0001';
  end if;
  insert into public.sga_cobros_incidencias (cliente_id, albaran_id, origen, producto_id, subtipo, fecha, cantidad, precio, importe, tarifa_id, motivos)
  values (new.cliente_id, new.albaran_id, new.origen, new.producto_id, new.subtipo, new.fecha, new.cantidad, new.precio, new.importe, new.tarifa_id,
          coalesce(v_nombre, new.producto_id) || ': ' || array_to_string(m, '; '));
  return new;
end $$;

drop trigger if exists sga_cobros_validar on public.sga_cobros;
create trigger sga_cobros_validar before insert on public.sga_cobros for each row execute function public.sga_cobro_validar();

notify pgrst, 'reload schema';

-- ============================================================
-- Comprobaciones (solo leen). Ejecútalas por separado.
-- ============================================================
-- 1) Debe salir «aviso»
-- select clave, valor from public.sga_ajustes where clave = 'validar_cobros';

-- 2) Cobros YA guardados que no cuadran con su tarifa (el histórico, para saber cómo están las cosas antes de pasar a «estricto»)
-- select c.fecha, a.numero_texto as albaran, k.nombre as cliente, c.origen, c.producto_id, c.subtipo, c.cantidad, c.precio, c.importe, t.precio as precio_tarifa,
--        case when c.tarifa_id is null then 'sin tarifa indicada'
--             when t.id is null then 'la tarifa ya no existe'
--             when abs(c.precio - t.precio) > 0.000001 then 'precio distinto al de la tarifa'
--             else 'importe no cuadra' end as problema
-- from public.sga_cobros c
-- left join public.almacenaje_tarifas t on t.id = c.tarifa_id
-- left join public.sga_albaranes a on a.id = c.albaran_id
-- left join public.contactos k on k.id = c.cliente_id
-- where c.origen in ('movimiento', 'servicio') and c.estado <> 'anulado'
--   and ( c.tarifa_id is null or t.id is null or abs(c.precio - t.precio) > 0.000001
--         or (abs(c.importe - round(c.cantidad * t.precio, 2)) > 0.01 and (t.importe_minimo is null or abs(c.importe - t.importe_minimo) > 0.01)) )
-- order by c.fecha desc limit 200;

-- Para pasar a modo estricto (cuando Revisión no muestre incidencias):
-- update public.sga_ajustes set valor = 'estricto', updated_at = now() where clave = 'validar_cobros';
-- Para volver a modo aviso:
-- update public.sga_ajustes set valor = 'aviso', updated_at = now() where clave = 'validar_cobros';

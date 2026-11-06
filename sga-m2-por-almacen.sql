-- ============================================================
-- QUALIFIED PROVEEDORES — m² contratados POR ALMACÉN
-- Cada cambio de m² del histórico de un cliente pasa a llevar también el almacén al que corresponde.
-- Así el dashboard, al elegir un almacén, cuenta los m² reales de ese almacén. El histórico con fechas se conserva tal cual
-- (los meses cerrados no cambian).
-- · Clientes con UN solo almacén asignado: todo su histórico de m² pasa a ese almacén automáticamente.
-- · Clientes con VARIOS almacenes: sus m² quedan «sin repartir» hasta que los anotes por almacén en su ficha (SGA → m² contratados).
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================

alter table public.sga_m2_contrato add column if not exists warehouse_id text references public.warehouses(id);
create index if not exists sga_m2_contrato_alm_idx on public.sga_m2_contrato (cliente_id, warehouse_id, vigente_desde desc);

-- Clientes con un solo almacén asignado: sus m² pasan a ese almacén
update public.sga_m2_contrato m
set warehouse_id = x.warehouse_id
from (
  select contacto_id, min(warehouse_id) as warehouse_id
  from public.contacto_warehouses
  group by contacto_id
  having count(*) = 1
) x
where m.cliente_id = x.contacto_id and m.warehouse_id is null;

notify pgrst, 'reload schema';

-- Clientes con m² que han quedado «sin repartir» (varios almacenes): hay que anotarlos por almacén en su ficha
select c.nombre as cliente, count(*) as cambios_sin_repartir
from public.sga_m2_contrato m
join public.contactos c on c.id = m.cliente_id
where m.warehouse_id is null
group by c.nombre
order by c.nombre;

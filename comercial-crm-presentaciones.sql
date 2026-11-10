-- ============================================================
-- QUALIFIED PROVEEDORES — Comercial → CRM → Presentaciones de empresa (Transporte y Almacén)
-- Se suben en CRM → Documentos con la categoría «Presentaciones», indicando de qué servicio es y en qué idioma.
-- Al generar el PDF de una oferta se pueden añadir al final: la de Transporte si se ha cotizado transporte
-- (aunque también se cotice almacén) y la de Almacén si solo se ha cotizado almacén u operativas.
-- Solo añade una categoría y dos columnas a la tabla de documentos; no cambia ni borra nada de lo que ya hay.
-- Es seguro ejecutarlo más de una vez.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run.
-- ============================================================
alter table public.crm_documentos add column if not exists servicio text;
alter table public.crm_documentos add column if not exists idioma text;

-- Se permite la categoría nueva (se sustituye la comprobación antigua de categorías, sea cual sea su nombre)
do $$
declare c text;
begin
  for c in select conname from pg_constraint
           where conrelid = 'public.crm_documentos'::regclass and contype = 'c' and pg_get_constraintdef(oid) ilike '%categoria%'
  loop
    execute format('alter table public.crm_documentos drop constraint %I', c);
  end loop;
end $$;

alter table public.crm_documentos add constraint crm_documentos_categoria_check
  check (categoria in ('competencia', 'cliente', 'contrato', 'otro', 'presentacion'));

alter table public.crm_documentos drop constraint if exists crm_documentos_servicio_check;
alter table public.crm_documentos add constraint crm_documentos_servicio_check
  check (servicio is null or servicio in ('transporte', 'almacen'));

alter table public.crm_documentos drop constraint if exists crm_documentos_idioma_check;
alter table public.crm_documentos add constraint crm_documentos_idioma_check
  check (idioma is null or idioma in ('es', 'ca', 'en', 'fr'));

notify pgrst, 'reload schema';

-- Comprobación: deben salir las 3 columnas y la categoría nueva
select column_name from information_schema.columns
where table_schema = 'public' and table_name = 'crm_documentos' and column_name in ('categoria', 'servicio', 'idioma')
order by column_name;

-- ============================================================
-- QUALIFIED PROVEEDORES — Tarifas de almacenaje: base de cobro del stock
-- Cada línea de stock se cobra:
--   'dia'     → cada noche, palets en stock × precio por palet y día (como hasta ahora)
--   'mes_max' → una vez al mes: el máximo de palets de ese tipo que hubo al acabar
--               algún día del mes × precio por palet y mes (mes entero, sin prorrateo)
-- Instrucciones: Supabase → SQL Editor → pega esto → Run.
-- ============================================================
alter table public.almacenaje_tarifas add column if not exists base_cobro text not null default 'dia';
notify pgrst, 'reload schema';

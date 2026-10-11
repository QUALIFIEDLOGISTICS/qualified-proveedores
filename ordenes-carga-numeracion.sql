-- =====================================================================
-- Órdenes de carga · nuevo formato de número: OC-0001, OC-0002…
-- (distinto del S0xxxxx que genera el otro programa, para no confundirlos).
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
--
--   · Las órdenes que ya hubiera se renumeran 1, 2, 3… por orden de creación.
--   · El contador sigue a partir de la última.
-- =====================================================================

update public.ordenes_carga o
set numero = s.rn
from (select id, row_number() over (order by created_at, id) as rn from public.ordenes_carga) s
where o.id = s.id;

select setval('public.oc_numero_seq', coalesce((select max(numero) from public.ordenes_carga), 0) + 1, false);

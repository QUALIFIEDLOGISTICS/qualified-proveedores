-- ============================================================
-- QUALIFIED PROVEEDORES — SGA · nombres de los campos de la mercancía
--   «Referencia»  →  «Descripción»
--   «Descripción» →  «Código de artículo»
-- Solo cambia los que todavía llevan el nombre de serie (si alguien ya los renombró a mano, no se tocan).
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
update public.sga_campos set nombre = 'Código de artículo' where clave = 'descripcion' and nombre = 'Descripción';
update public.sga_campos set nombre = 'Descripción'        where clave = 'referencia'  and nombre = 'Referencia';

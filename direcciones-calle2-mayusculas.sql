-- ============================================================
-- QUALIFIED PROVEEDORES — Direcciones: «Calle 2» en MAYÚSCULAS
-- Pasa a mayúsculas la calle 2 de todas las direcciones ya creadas.
-- Instrucciones: Supabase → SQL Editor → pega esto ENTERO → Run. Se puede ejecutar más de una vez.
-- ============================================================
update public.direcciones
   set calle2 = upper(calle2)
 where calle2 is not null and calle2 <> upper(calle2);

-- =====================================================================
-- Transportistas · verificación
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
--
--   Igual que en Direcciones: cualquiera con acceso crea el transportista y otra persona comprueba que está bien.
--   Los que ya existían quedan «sin verificar» hasta que se revisen (o se verifican todos de golpe desde la pantalla).
--
--   transp_creado_por     Quién lo dio de alta como transportista (lo verifica otra persona; los administradores pueden verificar cualquiera).
--   transp_verificado     true cuando alguien ha comprobado que está bien.
--   transp_verificado_por Quién lo verificó.   transp_verificado_at  Cuándo.
-- =====================================================================

alter table public.contactos add column if not exists transp_creado_por text;
alter table public.contactos add column if not exists transp_verificado boolean not null default false;
alter table public.contactos add column if not exists transp_verificado_por text;
alter table public.contactos add column if not exists transp_verificado_at timestamptz;

-- =====================================================================
-- Direcciones · verificación
-- Pega todo esto en Supabase → SQL Editor → Run. Se puede ejecutar más de una vez.
--
--   Cualquiera con acceso a Direcciones puede crearlas; después otra persona las revisa y las marca como verificadas.
--   Las que ya existían quedan «sin verificar» hasta que se revisen (o se verifiquen todas de golpe desde la pantalla).
--
--   created_by      Quién la creó (la verifica otra persona; los administradores pueden verificar cualquiera).
--   verificada      true cuando alguien ha comprobado que está bien creada.
--   verificada_por  Quién la verificó.   verificada_at  Cuándo.
-- =====================================================================

alter table public.direcciones add column if not exists created_by text;
alter table public.direcciones add column if not exists verificada boolean not null default false;
alter table public.direcciones add column if not exists verificada_por text;
alter table public.direcciones add column if not exists verificada_at timestamptz;

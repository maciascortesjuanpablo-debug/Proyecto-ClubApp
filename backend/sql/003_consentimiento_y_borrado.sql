-- Consentimiento (prueba de la autorización) y borrado real de cuentas.
-- EJECUTAR EN SUPABASE (SQL Editor) ANTES de desplegar el backend nuevo.

alter table usuarios
  add column if not exists acepto_terminos_en timestamptz,
  add column if not exists version_politica text,
  add column if not exists autorizacion_acudiente boolean not null default false,
  add column if not exists eliminacion_programada_en timestamptz,
  add column if not exists anonimizado_en timestamptz;

-- Acelera la búsqueda diaria de cuentas cuyo plazo de eliminación ya venció
create index if not exists usuarios_eliminacion_pendiente_idx
  on usuarios (eliminacion_programada_en)
  where anonimizado_en is null and eliminacion_programada_en is not null;

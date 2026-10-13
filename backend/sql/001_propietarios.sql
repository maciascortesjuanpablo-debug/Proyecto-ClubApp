-- Dueño del equipo: permite que solo quien lo creó (o un Admin) pueda modificarlo.
-- Ejecutar una vez en el SQL Editor de Supabase. Detecta solo el tipo de usuarios.id (uuid o bigint).
do $$
declare tipo text;
begin
  select format_type(atttypid, atttypmod) into tipo
  from pg_attribute
  where attrelid = 'public.usuarios'::regclass and attname = 'id';

  execute format(
    'alter table public.equipos add column if not exists creado_por %s references public.usuarios(id) on delete set null',
    tipo
  );
end $$;

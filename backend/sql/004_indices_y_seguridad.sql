-- Índices, RLS y limpieza. EJECUTAR EN SUPABASE (SQL Editor) DESPUÉS de 003_consentimiento_y_borrado.sql.
-- Todo es repetible (if not exists) y no borra datos. Los nombres de columnas salen del esquema real de la base.

-- ============ 1. ÍNDICES (las llaves foráneas no se indexan solas en Postgres) ============
create index if not exists eventos_torneo_fecha_idx     on eventos_calendario (torneo_id, fecha);
create index if not exists eventos_fecha_idx            on eventos_calendario (fecha);
create index if not exists eventos_local_idx            on eventos_calendario (equipo_local_id);
create index if not exists eventos_visitante_idx        on eventos_calendario (equipo_visitante_id);

create index if not exists inscripciones_torneo_idx     on inscripciones_equipo (torneo_id, estado);
create index if not exists inscripciones_equipo_idx     on inscripciones_equipo (equipo_id);

create index if not exists equipo_jugadores_equipo_idx  on equipo_jugadores (equipo_id);
create index if not exists equipo_jugadores_usuario_idx on equipo_jugadores (usuario_id);
create index if not exists equipo_staff_equipo_idx      on equipo_staff (equipo_id);
create index if not exists equipo_staff_usuario_idx     on equipo_staff (usuario_id);
create index if not exists equipos_creado_por_idx       on equipos (creado_por);

create index if not exists torneos_organizador_idx      on torneos (organizador_id);
create index if not exists torneos_estado_idx           on torneos (estado);

create index if not exists estadisticas_evento_idx      on estadisticas_jugador (evento_id);
create index if not exists estadisticas_usuario_idx     on estadisticas_jugador (usuario_id);
create index if not exists estadisticas_equipo_idx      on estadisticas_jugador (equipo_id);

create index if not exists notificaciones_usuario_idx   on notificaciones (usuario_id, leida, creado_en desc);
create index if not exists favoritos_usuario_idx        on favoritos (usuario_id);
create index if not exists invitaciones_usuario_idx     on invitaciones_equipo (usuario_id, estado);
create index if not exists invitaciones_equipo_idx      on invitaciones_equipo (equipo_id);
create index if not exists arbitros_evento_idx          on partido_arbitros (evento_id);
create index if not exists arbitros_usuario_idx         on partido_arbitros (usuario_id);
create index if not exists posiciones_inscripcion_idx   on tabla_posiciones (inscripcion_id);

create index if not exists codigos_busqueda_idx         on codigos_verificacion (usuario_id, tipo, usado, expira_en);
create index if not exists scout_conv_usuario_idx       on scout_ai_conversaciones (usuario_id);
create index if not exists scout_msg_conv_idx           on scout_ai_mensajes (conversacion_id, creado_en);
create index if not exists perfil_usuario_idx           on perfil_jugador (usuario_id);

-- ============ 2. RLS: el backend usa la clave secreta (ignora RLS), así que se activa SIN políticas ============
-- Efecto: si algún día se filtra la clave pública (anon), esa clave no puede leer ni escribir nada.
-- Si el backend dejara de funcionar tras esto, revisa que SUPABASE_KEY sea la clave sb_secret_ / service_role.
alter table usuarios                  enable row level security;
alter table codigos_verificacion      enable row level security;
alter table perfil_jugador            enable row level security;
alter table equipos                   enable row level security;
alter table equipo_jugadores          enable row level security;
alter table equipo_staff              enable row level security;
alter table torneos                   enable row level security;
alter table inscripciones_equipo      enable row level security;
alter table tabla_posiciones          enable row level security;
alter table eventos_calendario        enable row level security;
alter table estadisticas_jugador      enable row level security;
alter table partido_arbitros          enable row level security;
alter table sedes_canchas             enable row level security;
alter table notificaciones            enable row level security;
alter table favoritos                 enable row level security;
alter table invitaciones_equipo       enable row level security;
alter table scout_ai_conversaciones   enable row level security;
alter table scout_ai_mensajes         enable row level security;
alter table scout_ai_recomendaciones  enable row level security;
alter table scout_ai_reportes         enable row level security;
alter table pagos_inscripcion         enable row level security;
alter table admin_log                 enable row level security;
alter table roles                     enable row level security;
alter table deportes                  enable row level security;
alter table formatos                  enable row level security;

-- ============ 3. LIMPIEZA OPCIONAL (borra columnas: ejecútalo solo si estás seguro) ============
-- Columnas heredadas de un sistema anterior de verificación; el código actual no las usa.
-- alter table usuarios
--   drop column if exists "codigoVerificacion",
--   drop column if exists "codigoVerificacionExpiracion",
--   drop column if exists "codigoIntentos";

-- Evita que dos cuentas compartan correo cambiando mayúsculas. Fallará si ya hay duplicados: revísalo antes con
--   select lower(correo), count(*) from usuarios group by 1 having count(*) > 1;
-- create unique index if not exists usuarios_correo_unico_idx on usuarios (lower(correo));

# Cambios: pantallas y permisos por rol

## Cómo funciona
`MainShell` (tras iniciar sesión) elige la navegación según el rol de la sesión. Cada rol tiene su propia barra inferior
y sus pantallas; todas están envueltas en `RoleGuard`, y el backend vuelve a validar el rol en cada petición.

| Rol | Pestañas |
|---|---|
| Jugador | Inicio · Torneos · Mi equipo (solo consulta) · Calendario · Perfil (con estadísticas de juego) |
| Entrenador | Inicio · Torneos · Equipos (plantilla, invitaciones, inscripciones) · Calendario · Perfil |
| Organizador | Inicio · Mis torneos (+crear) · Inscripciones · Calendario · Perfil |
| Árbitro | Inicio · Partidos (por dirigir / historial) · Calendario (solo designaciones) · Perfil (sin estadísticas de jugador) |
| Admin | Panel (estadísticas visuales) · Torneos · Calendario · Perfil |
| Invitado / sin rol | Navegación general de consulta (la de antes) |

## Torneo (`screens/torneo/`)
Pestañas: Resumen · Posiciones · Partidos (enfrentamientos por día) · Equipos · Calendario (solo organizador dueño y admin:
elige un día y programa el partido; respeta la ventana de 40 días).

## Modelos
`ClubApp/lib/models/` (Usuario, Equipo, Torneo, Inscripcion, Partido, FilaPosicion, estadísticas, paneles por rol, ResumenTorneo, AdminResumen)
y servicios tipados `panel_service.dart`, `team_service.dart`. En el backend: `models/panel.js`.

## Backend nuevo
- `GET /api/panel/{jugador|entrenador|organizador|arbitro}` (cada uno solo para su rol)
- `GET /api/torneos/:id/resumen` (público)
- `GET /api/equipos/mios`, `GET /api/equipos/:id/partidos`, `GET /api/equipos/buscar-jugadores`
- `GET /api/admin/resumen` ahora incluye `series` para los gráficos

## Permisos que cambiaron (a propósito)
- Crear/gestionar equipos, inscribir equipos e invitar jugadores: solo **Entrenador** y Admin (antes también Organizador).
- Responder invitaciones: solo **Jugador**.
- `GET /torneos/organizador/:id`: solo el propio organizador o Admin.
- `GET /calendario/mis-eventos`: cada rol ve únicamente su relación (equipo, arbitraje u organización).
- Quien no es jugador ya no ve ni edita "nivel de juego" ni "perfil de jugador"; su perfil solo guarda la foto.

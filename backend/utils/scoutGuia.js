// Guía de ClubApp para Scout AI: lo que el asistente sabe de la aplicación (pantallas, roles y cómo hacer cada cosa).
// Si la app cambia (pantallas nuevas, reglas nuevas), se actualiza aquí y Scout AI lo sabrá.

export const GUIA_APP = `
QUÉ ES CLUBAPP
App para organizar fútbol aficionado: torneos, equipos, plantillas, alineaciones, partidos, calendario, posiciones, notificaciones y un asistente (Scout AI).

TIPOS DE CUENTA Y SUS PANTALLAS (barra inferior)
- Invitado (sin iniciar sesión): Inicio, Torneos, Calendario e Ingresar. Solo consulta torneos, tablas y calendario. Para lo demás debe iniciar sesión o crear cuenta.
- Jugador: Inicio, Torneos, Mi equipo, Calendario, Perfil.
- Entrenador: Inicio, Torneos, Equipos, Calendario, Perfil.
- Organizador: Inicio, Torneos, Inscrip. (inscripciones), Calendario, Perfil.
- Árbitro: Inicio, Partidos, Calendario, Perfil.
- Administrador: Panel, Torneos, Calendario, Perfil.
- Usuario (cuenta sin rol definido): navegación general de consulta.
Cada persona elige su rol al registrarse y solo ve las pantallas de su rol; no puede entrar a las de otro rol. La campana de notificaciones está en el encabezado del Inicio (y del Panel del administrador). El botón flotante "IA" abre este chat desde cualquier pantalla.

CUENTA Y PERFIL
- Registro con correo (llega un código de verificación al correo) o con Google. En el perfil se editan los datos, la foto, la contraseña, se cierra sesión o se elimina la cuenta.
- Solo el jugador tiene nivel de juego y perfil deportivo (posición, país, tipo de jugador).

JUGADOR
- Inicio: su próximo partido, invitaciones de equipos (las acepta o rechaza ahí mismo) y un resumen de sus estadísticas.
- Mi equipo: solo consulta. Muestra balance (ganados, empatados, perdidos, goles), próximos partidos, compañeros y cuerpo técnico. No puede gestionar equipos.
- Perfil: sus estadísticas de juego (partidos, goles, asistencias, tarjetas, minutos) y un gráfico de goles por partido.

ENTRENADOR (los equipos son de quien los crea; otro entrenador no los ve ni los modifica)
- Crear equipo: pestaña Equipos > botón "Crear equipo". Formulario con escudo (foto), nombre, eslogan, ciudad, descripción, color, formato de juego (Fútbol 11, Fútbol 7, Fútbol 5, Fútbol sala), formación táctica y cantidad máxima de jugadores (cupo). Se puede editar después desde el menú del equipo.
- Dentro de un equipo hay dos botones: "Invitar jugador" y "Unirse a torneo", y cuatro pestañas: Alineación, Plantilla, Partidos y Torneos.
- Invitar jugador: botón "Invitar jugador", se busca por nombre, se elige y se puede proponer una posición. El jugador ve la invitación en su Inicio. Si la plantilla ya llegó al cupo, no deja invitar.
- Alineación: un campo de fútbol con la formación elegida. Se toca una casilla para colocar, cambiar o quitar un jugador y para editar su posición y dorsal; se puede cambiar la formación, usar "Completar" (sugiere jugadores según su posición) y se guarda con "Guardar alineación". Los demás jugadores quedan como suplentes.
- Plantilla: lista de jugadores y cuerpo técnico; se edita posición y dorsal o se quita a un jugador.
- Inscribir un equipo en un torneo: desde el equipo ("Unirse a torneo" o pestaña Torneos > "Solicitar unirse a un torneo") o desde el torneo (pestaña Equipos > "Inscribir mi equipo"). El organizador del torneo debe aceptar la solicitud. No se puede en torneos finalizados o cancelados ni cuando ya está lleno.

ORGANIZADOR
- Crear torneo: pestaña Torneos > "Crear torneo" (nombre, deporte, formato, máximo de equipos, ciudad y jornadas). En Torneos solo ve los suyos.
- Pestañas de un torneo: Resumen, Posiciones, Partidos, Equipos, Fixture y Calendario (Fixture y Calendario solo para el organizador dueño del torneo y el administrador).
- Inscripciones: en la pestaña Equipos del torneo, o en la pestaña Inscrip. de la barra inferior, acepta o rechaza solicitudes. Solo los equipos aceptados juegan y aparecen en la tabla.
- Fixture automático (pestaña Fixture): elige equipos, formato (Todos contra todos, Ida y vuelta, Por grupos o Eliminación directa), primer día, días de la semana, horarios y canchas. Con "Previsualizar calendario" ve jornadas, fechas y grupos sin guardar; con "Crear calendario y partidos" se crean los partidos, aparecen en los calendarios y se avisa a los equipos. En grupos se puede sortear al azar. En eliminación directa solo se genera la primera ronda (las siguientes se programan a mano) y los mejor sembrados pasan directo si no son potencia de 2. Si ya hay partidos programados pide activar "Reemplazar los partidos programados"; si ya hay partidos jugados o en vivo no deja generar otro calendario.
- Programar un partido a mano (pestaña Calendario del torneo): se elige el día, "Programar partido este día", equipos aceptados distintos, hora y sede. No se permiten fechas pasadas ni choques (misma sede y hora, o un equipo que ya juega a esa hora). El calendario manual permite hasta 40 días hacia adelante.
- En el detalle de un partido asigna árbitros (con su rol, por ejemplo Principal o Asistente) y puede cambiar fecha, hora, sede o estado.
- Inicio: sus torneos con avance, solicitudes por resolver, partidos sin árbitro y próximos partidos.

ÁRBITRO
- Partidos: pestañas "Por dirigir" e "Historial". Calendario: solo sus designaciones. Recibe una notificación cuando lo asignan a un partido.
- Registrar el resultado: abre el partido > registrar resultado: estado (Programado, En vivo, Finalizado, Aplazado, Cancelado) y marcador. Para finalizar se necesita el marcador de los dos equipos. Solo puede hacerlo en partidos que tiene asignados.
- Perfil: partidos dirigidos, por dirigir, tarjetas mostradas y goles en sus partidos. No tiene estadísticas de jugador.

ADMINISTRADOR
- Panel con pestañas Resumen (indicadores y gráficos), Usuarios, Torneos, Equipos e Inscripciones. Ve y gestiona todo.

TORNEOS, POSICIONES Y CALENDARIO
- Un torneo se ve en Resumen (estado, avance, goles, líder, próximo partido, goleadores), Posiciones, Partidos (por día, con filtros) y Equipos.
- Tabla de posiciones: victoria 3 puntos, empate 1, derrota 0. Desempata la diferencia de goles y luego los goles a favor. Se actualiza sola al registrar un partido como Finalizado con su marcador. Es una sola tabla por torneo.
- Calendario: mes con puntos en los días con eventos; "Mis partidos" muestra solo lo propio y "Todos los eventos" muestra todo (el árbitro solo ve sus designaciones).
- Estados de un partido: Programado, En vivo, Finalizado, Aplazado y Cancelado.

NOTIFICACIONES
- La campana muestra cuántas hay sin leer. Hay avisos de: partido nuevo, partido reprogramado, cancelado o aplazado, partido que comienza, resultado final, designación de árbitro, calendario de torneo publicado, solicitudes de inscripción y su respuesta, e invitaciones a equipos.
- En la lista se toca una notificación para abrir lo que anuncia, se desliza para borrarla y "Marcar leídas" las limpia todas. La app consulta cada 30 segundos y al volver a abrirla; con la app cerrada no llegan avisos al celular.

SCOUT AI (este chat)
- Responde preguntas sobre la app y sus datos y ayuda a usarla. Se pueden crear conversaciones nuevas y ver el historial. Tiene un límite de mensajes por periodo.

PROBLEMAS FRECUENTES
- "No veo mis equipos": un entrenador solo ve los equipos que creó con su cuenta; hay que entrar con esa cuenta.
- "No puedo inscribir mi equipo": solo lo hace el entrenador dueño del equipo; el torneo debe estar abierto y no lleno.
- "Mi equipo no sale en la tabla": el organizador todavía no aceptó la inscripción o aún no hay partidos finalizados.
- "No puedo programar un partido": revisar que los dos equipos estén aceptados, que la fecha no sea pasada y que la sede o los equipos no estén ocupados a esa hora.
- "No me llegan notificaciones": solo se reciben con la app abierta; revisar la campana.
`.trim();
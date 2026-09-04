---

# 🏆 CLUBAPP - PLATAFORMA DE GESTIÓN DEPORTIVA

---

APLICACIÓN MÓVIL PARA LA GESTIÓN INTEGRAL DE TORNEOS, EQUIPOS, CALENDARIOS Y ESTADÍSTICAS DEPORTIVAS, DESARROLLADA CON UNA ARQUITECTURA MODERNA Y ESCALABLE

---

## 📋 Descripción

**ClubApp** es una plataforma deportiva integral pensada para comunidades amateur y semi-profesionales en Colombia. Permite crear y administrar torneos, gestionar equipos y plantillas, programar calendarios de partidos, llevar estadísticas de jugadores, procesar pagos de inscripción y contar con un asistente inteligente (**ScoutAI**) para recomendaciones y análisis de rendimiento.

---

## 🛠️ Stack Tecnológico

El proyecto utiliza una arquitectura moderna basada en un cliente móvil, un servidor backend y una base de datos en la nube, integrando las siguientes tecnologías:

- **Node.js + Express** (backend)
- **Supabase** (base de datos PostgreSQL + autenticación)
- **Flutter** (frontend)
- **JWT** para el manejo de sesiones
- **Bcrypt** para el cifrado de contraseñas
- **Brevo API** para el envío transaccional de correos

---

## 🚀 Características del Proyecto

### 🔐 1. Autenticación y Seguridad

- **Registro e Inicio de Sesión**: Autenticación segura para usuarios mediante tokens (JWT).
- **Control de Acceso Basado en Roles (RBAC)**: Vistas y permisos diferenciados para 6 perfiles: **Usuario**, **Jugador**, **Entrenador**, **Organizador**, **Árbitro** y **Admin**.
- **Protección de Rutas**: Middlewares en el backend para restringir el acceso a endpoints sensibles según el rol.
- **Recuperación de Contraseña**: Flujo de 3 pasos con código de verificación enviado por correo y expiración automática.
- **Gestión de Sesión**: Cierre de sesión seguro y expiración automática de credenciales.

### 🏟️ 2. Gestión de Torneos

- Creación de torneos por deporte (Fútbol 11, Fútbol 5, Baloncesto, Voleibol) y formato (Liga, Eliminación, Grupos, Mixto).
- Organización por grupos y tabla de posiciones en tiempo real.
- Inscripción de equipos con estado de aprobación (Pendiente, Aceptado, Rechazado).

### 👥 3. Gestión de Equipos

- Administración de plantillas de jugadores por posición y dorsal.
- Cuerpo técnico (entrenadores y staff) asociado a cada equipo.
- Sistema de invitaciones para que los jugadores se unan a un equipo.

### 📅 4. Calendario y Partidos

- Programación de partidos, entrenamientos y convocatorias.
- Asignación de sedes/canchas y árbitros por partido.
- Registro de resultados y actualización automática de la tabla de posiciones.

### 📊 5. Estadísticas

- Registro de goles, asistencias, tarjetas y minutos jugados por partido.
- Historial de rendimiento por jugador a lo largo del torneo.

### 💳 6. Pagos

- Gestión de pagos de inscripción de equipos a torneos.
- Integración con pasarelas de pago externas mediante webhook de confirmación.

### 🤖 7. ScoutAI

- Asistente inteligente con historial de conversación.
- Recomendaciones de jugadores para organizadores y entrenadores.
- Generación de reportes de rendimiento por jugador o por equipo.

### 🔔 8. Notificaciones y Favoritos

- Notificaciones de convocatorias, recordatorios y resultados.
- Sistema de favoritos para seguir torneos y equipos de interés.

---

## ⚙️ Instalación y Configuración

### 1. Clonar el repositorio

- git clone https://github.com/maciascortesjuanpablo-debug/Proyecto-ClubApp.git
- Instalacion de node
- instalar npm install
- Instalar libreria de node express
- Instalar libreria de superbase

### 2. ejecutar el Servidor

** npm run dev

---

## 📁 Estructura del Proyecto

```
Proyecto-ClubApp/
├── backend/
│   ├── config/          # Conexión a Supabase
│   ├── controllers/     # Lógica de negocio por módulo
│   ├── middlewares/     # Validación de JWT y roles
│   ├── models/          # Acceso a datos (Supabase)
│   ├── routes/          # Definición de rutas API
│   ├── utils/           # Envío de correos (Brevo)
│   ├── .env
│   └── index.js         # Servidor principal Express
│
└── frontend/
    ├── lib/
    │   ├── models/       # Modelos Dart
    │   ├── providers/    # Manejo de estado
    │   ├── screens/      # Pantallas (Login, Torneos, Equipos, Perfil...)
    │   ├── widgets/       # Componentes visuales reutilizables
    │   └── main.dart      # Punto de entrada de la aplicación
```

---

## 🗄️ Base de Datos

La base de datos fue diseñada en **Supabase (PostgreSQL)** con más de 25 tablas relacionadas, organizadas en los siguientes módulos:

- **Cuentas**: usuarios, roles, perfil_jugador, codigos_verificacion
- **Torneos**: torneos, grupos_torneo, deportes, formatos
- **Equipos**: equipos, equipo_jugadores, equipo_staff, inscripciones_equipo, invitaciones_equipo, tabla_posiciones
- **Calendario**: eventos_calendario, sedes_canchas, partido_arbitros
- **Rendimiento**: estadisticas_jugador
- **Pagos**: pagos_inscripcion
- **IA**: scout_ai_conversaciones, scout_ai_mensajes, scout_ai_recomendaciones, scout_ai_reportes
- **Sistema**: notificaciones, favoritos

---

## 👨‍💻 Autores

- **Juan Pablo Macías Cortés**
  - *Tecnólogo en Análisis y Desarrollo de Software - SENA*
 
- **Andrés Felipe Triviño Bustos**
  - *Tecnólogo en Análisis y Desarrollo de Software - SENA*

---

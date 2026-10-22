import 'package:flutter/material.dart';

/// Nombre de cada rol (ids de la tabla `roles`)
const rolesNombre = {1: 'Usuario', 2: 'Jugador', 3: 'Entrenador', 4: 'Organizador', 5: 'Árbitro', 6: 'Administrador'};

const nivelesJuego = ['Principiante', 'Intermedio', 'Amateur Competitivo', 'Profesional'];

/// Roles que una persona puede elegir al crear su cuenta: nombre -> (icono, id en la tabla `roles`)
const rolesRegistro = {
  'Jugador': (Icons.person_3, 2),
  'Entrenador': (Icons.sports_score, 3),
  'Organizador': (Icons.groups, 4),
  'Árbitro': (Icons.sports_score_outlined, 5),
};
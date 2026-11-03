/// Formatos de juego y formaciones tácticas disponibles para armar la alineación en el campo.
class Formaciones {
  static const formatos = ['Fútbol 11', 'Fútbol 7', 'Fútbol 5', 'Fútbol sala'];

  static const _porFormato = {
    'Fútbol 11': ['4-4-2', '4-3-3', '3-5-2', '4-2-3-1', '5-3-2', '3-4-3', '4-5-1'],
    'Fútbol 7': ['2-3-1', '3-2-1', '2-2-2', '1-3-2'],
    'Fútbol 5': ['2-2', '1-2-1', '2-1-1', '1-1-2'],
    'Fútbol sala': ['2-2', '1-2-1', '2-1-1', '1-1-2'],
  };

  /// Cantidad de jugadores en cancha por formato (portero incluido)
  static int jugadoresEnCancha(String formato) => switch (formato) { 'Fútbol 7' => 7, 'Fútbol 5' || 'Fútbol sala' => 5, _ => 11 };

  /// Cupo sugerido de plantilla por formato
  static int cupoSugerido(String formato) => switch (formato) { 'Fútbol 7' => 14, 'Fútbol 5' || 'Fútbol sala' => 10, _ => 22 };

  static List<String> de(String? formato) => _porFormato[formato] ?? _porFormato['Fútbol 11']!;

  static String porDefecto(String? formato) => de(formato).first;

  /// Jugadores por línea sin contar al portero: "4-4-2" -> [4, 4, 2]
  static List<int> lineas(String formacion) => formacion.split('-').map((e) => int.tryParse(e) ?? 0).where((n) => n > 0).toList();

  /// Total de casillas en el campo (portero + líneas)
  static int casillas(String formacion) => 1 + lineas(formacion).fold(0, (a, b) => a + b);

  /// Rol que corresponde a una casilla: 0 = Portero; la primera línea = Defensa; la última = Delantero; el resto = Mediocampista
  static String rolDeCasilla(String formacion, int slot) {
    if (slot == 0) return 'Portero';
    final l = lineas(formacion);
    var acumulado = 1;
    for (var i = 0; i < l.length; i++) {
      acumulado += l[i];
      if (slot < acumulado) return i == 0 ? 'Defensa' : (i == l.length - 1 ? 'Delantero' : 'Mediocampista');
    }
    return 'Mediocampista';
  }

  /// A qué línea del campo pertenece una posición escrita a mano ("Delantero centro", "Lateral", "Portero"...)
  static String rolDePosicion(String posicion) {
    final p = posicion.toLowerCase();
    if (p.contains('port') || p.contains('arquero') || p.contains('guardameta')) return 'Portero';
    if (p.contains('def') || p.contains('lateral') || p.contains('central') || p.contains('zaguero') || p.contains('líbero')) return 'Defensa';
    if (p.contains('del') || p.contains('extremo') || p.contains('punta') || p.contains('ariete') || p.contains('9')) return 'Delantero';
    if (p.contains('med') || p.contains('volante') || p.contains('centrocamp') || p.contains('pivote') || p.contains('mediapunta')) return 'Mediocampista';
    return '';
  }
}
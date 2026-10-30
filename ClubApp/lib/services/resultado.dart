/// Resultado de una llamada al backend ya convertido a modelos: trae el dato o el mensaje de error.
class Resultado<T> {
  final T? dato;
  final String? error;
  const Resultado.ok(T this.dato) : error = null;
  const Resultado.fallo(String this.error) : dato = null;

  bool get ok => error == null;
}

class ApiConfig {
  ApiConfig._();

  // Indica si se utiliza el servidor remoto
  static const bool useRemote = true;

  // URL del backend Node.js / Express CON el prefijo /api incluido
  static const String _remoteUrl =
      'https://clubapp-ups7.onrender.com/api'; // <-- Agregado /api aquí

  // URL base para todas las peticiones
  static String get baseUrl {
    if (useRemote) {
      return _remoteUrl;
    }
    // Si usas local, asegúrate de si también requiere /api o no
    return 'http://10.0.2.2:3000/api'; 
  }

  static const String googleServerClientId = '52252720899-h0qh1954pf716ms37tkjccfilulf8frh.apps.googleusercontent.com';

  // Resto de configuraciones...
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> headersConToken(String token) => {
        ...headers,
        'Authorization': 'Bearer $token',
      };

  static const Duration timeout = Duration(seconds: 20);
}
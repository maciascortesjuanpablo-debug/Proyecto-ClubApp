class ApiConfig {
  ApiConfig._();

  // Indica si se utiliza el servidor remoto
  static const bool useRemote = true;

  // URL del backend Node.js / Express
  static const String _remoteUrl =
      'https://clubapp-ups7.onrender.com/';

  // URL base para todas las peticiones
  static String get baseUrl {
    if (useRemote) {
      return _remoteUrl;
    }

    return 'http://10.0.2.2:3000';
  }


  static const String googleServerClientId = '52252720899-h0qhl954pf716ms3t7kjccfilulf8frh.apps.googleusercontent.com';

  // Encabezados predeterminados
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Encabezados con autenticación
  static Map<String, String> headersConToken(String token) => {
        ...headers,
        'Authorization': 'Bearer $token',
      };

  // Tiempo máximo de espera
  static const Duration timeout = Duration(seconds: 20);
}

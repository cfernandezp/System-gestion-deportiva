/// Excepcion para errores del servidor/backend
/// Contiene informacion detallada del error RPC
class ServerException implements Exception {
  final String message;
  final String? code;
  final String? hint;

  ServerException({
    required this.message,
    this.code,
    this.hint,
  });

  @override
  String toString() {
    return 'ServerException: $message (code: $code, hint: $hint)';
  }
}

/// Excepcion para errores de cache local
class CacheException implements Exception {
  final String message;

  CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

/// Excepcion para errores de conexion de red
class NetworkException implements Exception {
  final String message;

  NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

/// Excepcion para errores de autenticacion
class AuthException implements Exception {
  final String message;

  AuthException({required this.message});

  @override
  String toString() => 'AuthException: $message';
}

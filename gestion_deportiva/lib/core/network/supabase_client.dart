import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuracion y acceso al cliente Supabase
/// Centraliza la conexion con el backend
class SupabaseConfig {
  // TODO: Configurar variables de entorno para produccion
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  /// Inicializa Supabase - llamar en main.dart antes de runApp
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// Obtiene el cliente Supabase
  static SupabaseClient get client => Supabase.instance.client;

  /// Obtiene el usuario actual autenticado
  static User? get currentUser => client.auth.currentUser;

  /// Verifica si hay un usuario autenticado
  static bool get isAuthenticated => currentUser != null;

  /// Obtiene el ID del usuario actual
  static String? get currentUserId => currentUser?.id;
}

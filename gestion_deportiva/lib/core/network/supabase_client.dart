import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuracion y acceso al cliente Supabase
/// Centraliza la conexion con el backend
class SupabaseConfig {
  // Variables de entorno para produccion (Vercel), con fallback para desarrollo local
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tvvubzkqbksxvcjvivij.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_KkJq9unjd4xC9YxQSmShZA_ATcIONaq',
  );

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

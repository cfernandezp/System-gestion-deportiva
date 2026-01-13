import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_client.dart';

/// Service Locator global
final sl = GetIt.instance;

/// Inicializa todas las dependencias de la aplicacion
/// Llamar en main.dart antes de runApp
Future<void> initializeDependencies() async {
  // ==================== Core ====================

  // Supabase Client
  sl.registerLazySingleton<SupabaseClient>(() => SupabaseConfig.client);

  // ==================== Features ====================

  // TODO: Registrar Blocs, Repositories, DataSources por feature
  // Ejemplo:
  // sl.registerFactory(() => AuthBloc(repository: sl()));
  // sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(dataSource: sl()));
  // sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(supabase: sl()));
}

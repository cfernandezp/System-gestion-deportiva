import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_client.dart';

// Auth Feature
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/registro/registro_bloc.dart';

/// Service Locator global
final sl = GetIt.instance;

/// Inicializa todas las dependencias de la aplicacion
/// Llamar en main.dart antes de runApp
Future<void> initializeDependencies() async {
  // ==================== Core ====================

  // Supabase Client
  sl.registerLazySingleton<SupabaseClient>(() => SupabaseConfig.client);

  // ==================== Features ====================

  // -------------------- Auth --------------------

  // Bloc
  sl.registerFactory(() => RegistroBloc(repository: sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabase: sl()),
  );
}

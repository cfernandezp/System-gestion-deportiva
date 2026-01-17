import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_client.dart';

// Auth Feature
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/login/login_bloc.dart';
import '../../features/auth/presentation/bloc/registro/registro_bloc.dart';
import '../../features/auth/presentation/bloc/recuperacion/recuperacion_bloc.dart';
import '../../features/auth/presentation/bloc/session/session_bloc.dart';

// Admin Feature (HU-005: Gestion de Roles)
import '../../features/admin/data/datasources/admin_remote_datasource.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/presentation/bloc/usuarios/usuarios_bloc.dart';

// Profile Feature (E002-HU-001: Ver Perfil Propio)
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/perfil/perfil_bloc.dart';

// Jugadores Feature (E002-HU-003: Lista de Jugadores, E002-HU-004: Ver Perfil de Otro Jugador)
import '../../features/jugadores/data/datasources/jugadores_remote_datasource.dart';
import '../../features/jugadores/data/repositories/jugadores_repository_impl.dart';
import '../../features/jugadores/domain/repositories/jugadores_repository.dart';
import '../../features/jugadores/presentation/bloc/jugadores/jugadores_bloc.dart';
import '../../features/jugadores/presentation/bloc/perfil_jugador/perfil_jugador_bloc.dart';

// Fechas Feature (E003-HU-001: Crear Fecha)
import '../../features/fechas/data/datasources/fechas_remote_datasource.dart';
import '../../features/fechas/data/repositories/fechas_repository_impl.dart';
import '../../features/fechas/domain/repositories/fechas_repository.dart';
import '../../features/fechas/presentation/bloc/crear_fecha/crear_fecha_bloc.dart';

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

  // Blocs
  sl.registerFactory(() => RegistroBloc(repository: sl()));
  sl.registerFactory(() => LoginBloc(repository: sl()));
  // RecuperacionBloc: Factory para flujo de recuperacion de contrasena (HU-003)
  sl.registerFactory(() => RecuperacionBloc(repository: sl()));
  // SessionBloc: Singleton para mantener estado de sesion global (HU-004)
  sl.registerLazySingleton(() => SessionBloc(
        repository: sl(),
        supabase: sl(),
      ));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabase: sl()),
  );

  // -------------------- Admin (HU-005) --------------------

  // Blocs
  sl.registerFactory(() => UsuariosBloc(repository: sl()));

  // Repository
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remoteDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(supabase: sl()),
  );

  // -------------------- Profile (E002-HU-001) --------------------

  // Blocs
  sl.registerFactory(() => PerfilBloc(repository: sl()));

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(supabase: sl()),
  );

  // -------------------- Jugadores (E002-HU-003, E002-HU-004) --------------------

  // Blocs
  sl.registerFactory(() => JugadoresBloc(repository: sl()));
  // E002-HU-004: Bloc para ver perfil de otro jugador
  sl.registerFactory(() => PerfilJugadorBloc(repository: sl()));

  // Repository
  sl.registerLazySingleton<JugadoresRepository>(
    () => JugadoresRepositoryImpl(remoteDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<JugadoresRemoteDataSource>(
    () => JugadoresRemoteDataSourceImpl(supabase: sl()),
  );

  // -------------------- Fechas (E003-HU-001) --------------------

  // Blocs
  // E003-HU-001: Crear Fecha
  sl.registerFactory(() => CrearFechaBloc(repository: sl()));

  // Repository
  sl.registerLazySingleton<FechasRepository>(
    () => FechasRepositoryImpl(remoteDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<FechasRemoteDataSource>(
    () => FechasRemoteDataSourceImpl(supabase: sl()),
  );
}

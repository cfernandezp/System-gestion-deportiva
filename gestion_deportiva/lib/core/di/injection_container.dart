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

// Fechas Feature (E003-HU-001: Crear Fecha, E003-HU-002: Inscribirse a Fecha, E003-HU-003: Ver Inscritos, E003-HU-004: Cerrar Inscripciones, E003-HU-007: Cancelar Inscripcion, E003-HU-008: Editar Fecha)
import '../../features/fechas/data/datasources/fechas_remote_datasource.dart';
import '../../features/fechas/data/repositories/fechas_repository_impl.dart';
import '../../features/fechas/domain/repositories/fechas_repository.dart';
import '../../features/fechas/presentation/bloc/crear_fecha/crear_fecha_bloc.dart';
import '../../features/fechas/presentation/bloc/inscripcion/inscripcion_bloc.dart';
import '../../features/fechas/presentation/bloc/fechas_disponibles/fechas_disponibles_bloc.dart';
import '../../features/fechas/presentation/bloc/editar_fecha/editar_fecha_bloc.dart';
import '../../features/fechas/presentation/bloc/inscritos/inscritos_bloc.dart';
import '../../features/fechas/presentation/bloc/cerrar_inscripciones/cerrar_inscripciones_bloc.dart';
import '../../features/fechas/presentation/bloc/cancelar_inscripcion/cancelar_inscripcion_bloc.dart';
import '../../features/fechas/presentation/bloc/asignaciones/asignaciones_bloc.dart';
import '../../features/fechas/presentation/bloc/mi_equipo/mi_equipo_bloc.dart';
import '../../features/fechas/presentation/bloc/fechas_por_rol/fechas_por_rol_bloc.dart';
import '../../features/fechas/presentation/bloc/finalizar_fecha/finalizar_fecha_bloc.dart';

// Solicitudes Feature (E001-HU-006: Gestionar Solicitudes de Registro)
import '../../features/solicitudes/data/datasources/solicitudes_remote_datasource.dart';
import '../../features/solicitudes/data/repositories/solicitudes_repository_impl.dart';
import '../../features/solicitudes/domain/repositories/solicitudes_repository.dart';
import '../../features/solicitudes/presentation/bloc/solicitudes/solicitudes_bloc.dart';

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

  // -------------------- Fechas (E003-HU-001, E003-HU-002, E003-HU-003, E003-HU-004, E003-HU-007, E003-HU-008) --------------------

  // Blocs
  // E003-HU-001: Crear Fecha
  sl.registerFactory(() => CrearFechaBloc(repository: sl()));
  // E003-HU-002: Inscribirse a Fecha
  sl.registerFactory(() => InscripcionBloc(repository: sl()));
  sl.registerFactory(() => FechasDisponiblesBloc(repository: sl()));
  // E003-HU-003: Ver Inscritos
  sl.registerFactory(() => InscritosBloc(repository: sl(), supabase: sl()));
  // E003-HU-004: Cerrar Inscripciones
  sl.registerFactory(() => CerrarInscripcionesBloc(repository: sl()));
  // E003-HU-007: Cancelar Inscripcion
  sl.registerFactory(() => CancelarInscripcionBloc(repository: sl()));
  // E003-HU-008: Editar Fecha
  sl.registerFactory(() => EditarFechaBloc(repository: sl()));
  // E003-HU-005: Asignar Equipos
  sl.registerFactory(() => AsignacionesBloc(repository: sl()));
  // E003-HU-006: Ver Mi Equipo
  sl.registerFactory(() => MiEquipoBloc(repository: sl(), supabase: sl()));
  // E003-HU-009: Listar Fechas por Rol
  sl.registerFactory(() => FechasPorRolBloc(repository: sl()));
  // E003-HU-010: Finalizar Fecha
  sl.registerFactory(() => FinalizarFechaBloc(repository: sl()));

  // Repository
  sl.registerLazySingleton<FechasRepository>(
    () => FechasRepositoryImpl(remoteDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<FechasRemoteDataSource>(
    () => FechasRemoteDataSourceImpl(supabase: sl()),
  );

  // -------------------- Solicitudes (E001-HU-006) --------------------

  // Blocs
  // E001-HU-006: Gestionar Solicitudes de Registro
  sl.registerFactory(() => SolicitudesBloc(repository: sl()));

  // Repository
  sl.registerLazySingleton<SolicitudesRepository>(
    () => SolicitudesRepositoryImpl(remoteDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<SolicitudesRemoteDataSource>(
    () => SolicitudesRemoteDataSourceImpl(supabase: sl()),
  );
}

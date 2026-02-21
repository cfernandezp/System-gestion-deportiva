import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/crear_grupo_response_model.dart';
import '../models/editar_grupo_response_model.dart';
import '../models/grupo_model.dart';
import '../models/invitar_jugador_response_model.dart';
import '../models/miembro_grupo_model.dart';
import '../models/mi_grupo_model.dart';

/// DataSource remoto para operaciones de grupos
/// E002-HU-001: Crear Grupo Deportivo
abstract class GruposRemoteDataSource {
  /// RPC: crear_grupo
  /// CA-001 a CA-007: Crea un grupo deportivo
  Future<CrearGrupoResponseModel> crearGrupo({
    required String nombre,
    String? lema,
    String? reglas,
    String? logoUrl,
  });

  /// Sube logo del grupo a Supabase Storage
  /// CA-003 / RN-003: Solo JPG/PNG, max 2MB
  Future<String> subirLogoGrupo(File imagen);

  /// Cuenta grupos activos donde el usuario es admin creador
  /// CA-006: Para validar limite antes de crear
  Future<int> contarGruposComoAdmin();

  /// E002-HU-002: RPC obtener_mis_grupos
  /// CA-001: Lista de grupos del usuario con rol y miembros
  Future<List<MiGrupoModel>> obtenerMisGrupos();

  /// E002-HU-002: RPC registrar_acceso_grupo
  /// CA-004 / RN-003: Actualiza ultimo_acceso al entrar a un grupo
  Future<void> registrarAccesoGrupo(String grupoId);

  /// E001-HU-004: RPC invitar_jugador_grupo
  /// CA-001 a CA-004, CA-006, CA-007: Invita un jugador al grupo
  Future<InvitarJugadorResponseModel> invitarJugadorGrupo({
    required String grupoId,
    required String celular,
  });

  /// E001-HU-004: RPC obtener_miembros_grupo
  /// CA-005: Lista de miembros del grupo con estado
  Future<List<MiembroGrupoModel>> obtenerMiembrosGrupo(String grupoId);

  /// E002-HU-003: Obtiene detalle completo del grupo
  /// Query directa a tabla grupos (RLS permite)
  Future<GrupoModel> obtenerDetalleGrupo(String grupoId);

  /// E002-HU-003: RPC editar_grupo
  /// CA-001 a CA-005, RN-001 a RN-004: Edita nombre, logo, lema y reglas
  Future<EditarGrupoResponseModel> editarGrupo({
    required String grupoId,
    required String nombre,
    String? lema,
    String? reglas,
    String? logoUrl,
  });
}

/// Implementacion con Supabase
class GruposRemoteDataSourceImpl implements GruposRemoteDataSource {
  final supabase_lib.SupabaseClient supabase;

  GruposRemoteDataSourceImpl({required this.supabase});

  @override
  Future<CrearGrupoResponseModel> crearGrupo({
    required String nombre,
    String? lema,
    String? reglas,
    String? logoUrl,
  }) async {
    try {
      debugPrint('[GruposDS] Creando grupo: $nombre');

      final response = await supabase.rpc(
        'crear_grupo',
        params: {
          'p_nombre': nombre,
          'p_lema': lema,
          'p_reglas': reglas,
          'p_logo_url': logoUrl,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        final result = CrearGrupoResponseModel.fromJson(responseMap);
        debugPrint('[GruposDS] Grupo creado: ${result.grupoId}');
        return result;
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al crear grupo',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('[GruposDS] Error crearGrupo: $e');
      throw ServerException(message: 'Error de conexion: ${e.toString()}');
    }
  }

  @override
  Future<String> subirLogoGrupo(File imagen) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw ServerException(message: 'No autenticado');
      }

      // Generar nombre unico para el archivo
      final extension = imagen.path.split('.').last.toLowerCase();
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final filePath = 'logos/$fileName';

      debugPrint('[GruposDS] Subiendo logo: $filePath');

      await supabase.storage
          .from('grupo-logos')
          .upload(filePath, imagen);

      // Obtener URL publica
      final publicUrl = supabase.storage
          .from('grupo-logos')
          .getPublicUrl(filePath);

      debugPrint('[GruposDS] Logo subido: $publicUrl');
      return publicUrl;
    } on supabase_lib.StorageException catch (e) {
      debugPrint('[GruposDS] Error storage: ${e.message}');
      throw ServerException(
        message: 'Error al subir imagen: ${e.message}',
        hint: 'storage_error',
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      debugPrint('[GruposDS] Error subirLogo: $e');
      throw ServerException(message: 'Error al subir imagen: ${e.toString()}');
    }
  }

  @override
  Future<int> contarGruposComoAdmin() async {
    try {
      final authUid = supabase.auth.currentUser?.id;
      if (authUid == null) {
        throw ServerException(message: 'No autenticado');
      }

      // Obtener usuario_id
      final userResult = await supabase
          .from('usuarios')
          .select('id')
          .eq('auth_user_id', authUid)
          .single();

      final usuarioId = userResult['id'] as String;

      // Contar grupos activos como admin creador
      final result = await supabase
          .from('grupos')
          .select('id')
          .eq('admin_creador_id', usuarioId)
          .eq('activo', true);

      final count = (result as List).length;
      debugPrint('[GruposDS] Grupos como admin: $count');
      return count;
    } catch (e) {
      if (e is ServerException) rethrow;
      debugPrint('[GruposDS] Error contarGrupos: $e');
      throw ServerException(message: 'Error al contar grupos: ${e.toString()}');
    }
  }

  @override
  Future<List<MiGrupoModel>> obtenerMisGrupos() async {
    try {
      debugPrint('[GruposDS] Obteniendo mis grupos...');

      final response = await supabase.rpc('obtener_mis_grupos');
      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        final data = responseMap['data'] as List<dynamic>? ?? [];
        final grupos = data
            .map((g) => MiGrupoModel.fromJson(g as Map<String, dynamic>))
            .toList();
        debugPrint('[GruposDS] ${grupos.length} grupos obtenidos');
        return grupos;
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener grupos',
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('[GruposDS] Error obtenerMisGrupos: $e');
      throw ServerException(message: 'Error de conexion: ${e.toString()}');
    }
  }

  @override
  Future<void> registrarAccesoGrupo(String grupoId) async {
    try {
      debugPrint('[GruposDS] Registrando acceso a grupo: $grupoId');
      await supabase.rpc(
        'registrar_acceso_grupo',
        params: {'p_grupo_id': grupoId},
      );
    } catch (e) {
      debugPrint('[GruposDS] Error registrarAcceso: $e');
      // No lanzar excepcion, es una operacion secundaria
    }
  }

  @override
  Future<InvitarJugadorResponseModel> invitarJugadorGrupo({
    required String grupoId,
    required String celular,
  }) async {
    try {
      debugPrint('[GruposDS] Invitando jugador $celular al grupo $grupoId');

      final response = await supabase.rpc(
        'invitar_jugador_grupo',
        params: {
          'p_grupo_id': grupoId,
          'p_celular': celular,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        final result = InvitarJugadorResponseModel.fromJson(responseMap);
        debugPrint('[GruposDS] Jugador invitado: ${result.celular}');
        return result;
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al invitar jugador',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('[GruposDS] Error invitarJugador: $e');
      throw ServerException(message: 'Error de conexion: ${e.toString()}');
    }
  }

  @override
  Future<List<MiembroGrupoModel>> obtenerMiembrosGrupo(String grupoId) async {
    try {
      debugPrint('[GruposDS] Obteniendo miembros del grupo $grupoId');

      final response = await supabase.rpc(
        'obtener_miembros_grupo',
        params: {'p_grupo_id': grupoId},
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        final data = responseMap['data'] as List<dynamic>? ?? [];
        final miembros = data
            .map((m) => MiembroGrupoModel.fromJson(m as Map<String, dynamic>))
            .toList();
        debugPrint('[GruposDS] ${miembros.length} miembros obtenidos');
        return miembros;
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al obtener miembros',
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('[GruposDS] Error obtenerMiembros: $e');
      throw ServerException(message: 'Error de conexion: ${e.toString()}');
    }
  }

  @override
  Future<GrupoModel> obtenerDetalleGrupo(String grupoId) async {
    try {
      debugPrint('[GruposDS] Obteniendo detalle del grupo: $grupoId');

      final result = await supabase
          .from('grupos')
          .select()
          .eq('id', grupoId)
          .single();

      final grupo = GrupoModel.fromJson(result);
      debugPrint('[GruposDS] Detalle grupo obtenido: ${grupo.nombre}');
      return grupo;
    } catch (e) {
      if (e is ServerException) rethrow;
      debugPrint('[GruposDS] Error obtenerDetalleGrupo: $e');
      throw ServerException(message: 'Error al obtener detalle del grupo: ${e.toString()}');
    }
  }

  @override
  Future<EditarGrupoResponseModel> editarGrupo({
    required String grupoId,
    required String nombre,
    String? lema,
    String? reglas,
    String? logoUrl,
  }) async {
    try {
      debugPrint('[GruposDS] Editando grupo: $grupoId');

      final response = await supabase.rpc(
        'editar_grupo',
        params: {
          'p_grupo_id': grupoId,
          'p_nombre': nombre,
          'p_lema': lema,
          'p_reglas': reglas,
          'p_logo_url': logoUrl,
        },
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        final result = EditarGrupoResponseModel.fromJson(responseMap);
        debugPrint('[GruposDS] Grupo editado: ${result.nombre}');
        return result;
      } else {
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al editar grupo',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('[GruposDS] Error editarGrupo: $e');
      throw ServerException(message: 'Error de conexion: ${e.toString()}');
    }
  }
}

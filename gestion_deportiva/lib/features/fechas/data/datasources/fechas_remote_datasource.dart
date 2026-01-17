import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;

import '../../../../core/errors/exceptions.dart';
import '../models/crear_fecha_request_model.dart';
import '../models/crear_fecha_response_model.dart';

/// Interface del DataSource remoto de fechas
/// E003-HU-001: Crear Fecha
abstract class FechasRemoteDataSource {
  /// Crea una nueva fecha de pichanga
  /// RPC: crear_fecha(p_fecha_hora_inicio, p_duracion_horas, p_lugar)
  /// CA-001 a CA-007, RN-001 a RN-007
  Future<CrearFechaResponseModel> crearFecha(CrearFechaRequestModel request);
}

/// Implementacion del DataSource remoto de fechas
/// Llama a las funciones RPC de Supabase
class FechasRemoteDataSourceImpl implements FechasRemoteDataSource {
  final supabase_lib.SupabaseClient supabase;

  FechasRemoteDataSourceImpl({required this.supabase});

  @override
  Future<CrearFechaResponseModel> crearFecha(
      CrearFechaRequestModel request) async {
    try {
      // RPC: crear_fecha
      // Parametros: p_fecha_hora_inicio, p_duracion_horas, p_lugar
      final response = await supabase.rpc(
        'crear_fecha',
        params: request.toParams(),
      );

      final responseMap = response as Map<String, dynamic>;

      if (responseMap['success'] == true) {
        return CrearFechaResponseModel.fromJson(responseMap);
      } else {
        // Extraer error del response
        final error = responseMap['error'] as Map<String, dynamic>? ?? {};
        throw ServerException(
          message: error['message'] ?? 'Error al crear la fecha',
          code: error['code'],
          hint: error['hint'],
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error de conexion al crear fecha: ${e.toString()}',
      );
    }
  }
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/models.dart';

/// Repository abstracto de Mi Actividad
/// E004-HU-008: Mi Actividad en Vivo
/// Define las operaciones para obtener y observar la actividad del jugador
abstract class MiActividadRepository {
  /// Obtiene la actividad en vivo del jugador actual
  /// RPC: obtener_mi_actividad_vivo()
  /// CA-001 a CA-007, RN-001 a RN-004
  Future<Either<Failure, MiActividadResponseModel>> obtenerMiActividadVivo();

  /// Stream de cambios en tiempo real de goles
  /// RN-006: Actualizaciones automaticas via Realtime
  Stream<void> observarCambiosGoles(String fechaId);

  /// Stream de cambios en tiempo real de partidos
  /// RN-006: Actualizaciones automaticas via Realtime
  Stream<void> observarCambiosPartidos(String fechaId);
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/fechas_repository.dart';
import 'finalizar_fecha_event.dart';
import 'finalizar_fecha_state.dart';

/// BLoC para gestionar la finalizacion de fechas de pichanga
/// E003-HU-010: Finalizar Fecha
///
/// Funcionalidad:
/// - Permite al admin finalizar una fecha en estado 'en_juego' o 'cerrada'
/// - Registra comentarios opcionales e incidentes
/// - Actualiza el estado a 'finalizada' (terminal)
///
/// Reglas de Negocio:
/// - RN-001: Solo admin aprobado puede finalizar
/// - RN-002: Solo estados 'en_juego' o 'cerrada'
/// - RN-003: Estado terminal, no reversible
/// - RN-005: Descripcion obligatoria si huboIncidente = true
class FinalizarFechaBloc
    extends Bloc<FinalizarFechaEvent, FinalizarFechaState> {
  final FechasRepository repository;

  FinalizarFechaBloc({required this.repository})
      : super(const FinalizarFechaInitial()) {
    on<FinalizarFechaSubmitEvent>(_onFinalizarFecha);
    on<FinalizarFechaResetEvent>(_onReset);
  }

  /// Procesa la finalizacion de una fecha
  /// CA-001 a CA-006: Validacion y actualizacion de estado
  Future<void> _onFinalizarFecha(
    FinalizarFechaSubmitEvent event,
    Emitter<FinalizarFechaState> emit,
  ) async {
    emit(const FinalizarFechaLoading());

    // RN-005: Validacion local - si huboIncidente, descripcion es obligatoria
    if (event.huboIncidente &&
        (event.descripcionIncidente == null ||
            event.descripcionIncidente!.trim().isEmpty)) {
      emit(const FinalizarFechaError(
        message: 'Debes describir el incidente si marcaste que hubo uno',
        hint: 'descripcion_incidente_requerida',
      ));
      return;
    }

    final result = await repository.finalizarFecha(
      fechaId: event.fechaId,
      comentarios: event.comentarios?.trim(),
      huboIncidente: event.huboIncidente,
      descripcionIncidente: event.descripcionIncidente?.trim(),
    );

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(FinalizarFechaError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success) {
          emit(FinalizarFechaSuccess(
            data: response.data,
            message: response.message,
          ));
        } else {
          emit(FinalizarFechaError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al finalizar la fecha',
          ));
        }
      },
    );
  }

  /// Reinicia el estado del BLoC
  void _onReset(
    FinalizarFechaResetEvent event,
    Emitter<FinalizarFechaState> emit,
  ) {
    emit(const FinalizarFechaInitial());
  }
}

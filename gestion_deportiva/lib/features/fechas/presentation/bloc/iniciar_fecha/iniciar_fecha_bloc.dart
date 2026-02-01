import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/fechas_repository.dart';
import 'iniciar_fecha_event.dart';
import 'iniciar_fecha_state.dart';

/// BLoC para gestionar el inicio de fechas de pichanga
/// E003-HU-012: Iniciar Fecha
///
/// Funcionalidad:
/// - Permite al admin iniciar una fecha en estado 'cerrada'
/// - Cambia el estado a 'en_juego'
/// - Registra hora real de inicio y quien inicio
/// - Notifica a todos los jugadores inscritos
///
/// Criterios de Aceptacion:
/// - CA-001: Boton visible solo en estado cerrada
/// - CA-002: Confirmacion con resumen
/// - CA-003: Warning si no hay equipos asignados
/// - CA-004: Estado cambia a en_juego
/// - CA-005: Boton desaparece tras iniciar
/// - CA-006: Notificacion a jugadores inscritos
/// - CA-007: Registro de hora real de inicio
///
/// Reglas de Negocio:
/// - RN-001: Solo admin aprobado o creador puede iniciar
/// - RN-002: Solo estado 'cerrada' permite inicio
/// - RN-003: Warning si no hay equipos (no bloquea)
/// - RN-004: Registrar iniciado_por e iniciado_at
/// - RN-005: Notificacion automatica a inscritos
class IniciarFechaBloc extends Bloc<IniciarFechaEvent, IniciarFechaState> {
  final FechasRepository repository;

  IniciarFechaBloc({required this.repository})
      : super(const IniciarFechaInitial()) {
    on<IniciarFechaSubmitEvent>(_onIniciarFecha);
    on<IniciarFechaResetEvent>(_onReset);
  }

  /// Procesa el inicio de una fecha
  /// CA-004: Cambiar estado a en_juego
  /// CA-006: Notificacion a jugadores
  /// CA-007: Registro de hora real
  Future<void> _onIniciarFecha(
    IniciarFechaSubmitEvent event,
    Emitter<IniciarFechaState> emit,
  ) async {
    emit(const IniciarFechaLoading());

    final result = await repository.iniciarFecha(event.fechaId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(IniciarFechaError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success) {
          emit(IniciarFechaSuccess(
            data: response.data,
            message: response.message,
          ));
        } else {
          emit(IniciarFechaError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al iniciar la pichanga',
          ));
        }
      },
    );
  }

  /// Reinicia el estado del BLoC
  void _onReset(
    IniciarFechaResetEvent event,
    Emitter<IniciarFechaState> emit,
  ) {
    emit(const IniciarFechaInitial());
  }
}

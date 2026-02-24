import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/fechas_repository.dart';
import 'editar_fecha_event.dart';
import 'editar_fecha_state.dart';

/// BLoC para gestionar la edicion de fechas de pichanga
/// E003-HU-008: Editar Fecha
///
/// Criterios de Aceptacion:
/// - CA-001: Solo admin puede ver boton editar
/// - CA-002: Solo fechas con estado 'abierta' son editables
/// - CA-003: Formulario precargado con datos actuales
/// - CA-004: Duracion, num_equipos y costo independientes y editables
/// - CA-005: Validacion de fecha futura
/// - CA-006: Confirmacion con resumen de cambios
/// - CA-007: Notificacion a inscritos
/// - CA-008: Ajuste de deudas por cambio de costo
///
/// Reglas de Negocio:
/// - RN-001: Solo administradores pueden editar
/// - RN-002: Solo fechas con estado 'abierta'
/// - RN-004: Fecha futura obligatoria
/// - RN-005: Unicidad de fecha (no colision)
/// - RN-006: Ajuste de deudas pendientes
/// - RN-007: Notificacion obligatoria a inscritos
/// - RN-008: Registro de cambios (updated_at)
class EditarFechaBloc extends Bloc<EditarFechaEvent, EditarFechaState> {
  final FechasRepository repository;

  EditarFechaBloc({required this.repository})
      : super(const EditarFechaInitial()) {
    on<EditarFechaInicializarEvent>(_onInicializar);
    on<EditarFechaSubmitEvent>(_onEditarFecha);
    on<EditarFechaResetEvent>(_onReset);
  }

  /// CA-003: Inicializar formulario con datos actuales
  void _onInicializar(
    EditarFechaInicializarEvent event,
    Emitter<EditarFechaState> emit,
  ) {
    emit(EditarFechaFormularioListo(
      fechaId: event.fechaId,
      fechaHoraInicio: event.fechaHoraInicio,
      duracionHoras: event.duracionHoras,
      lugar: event.lugar,
      numEquipos: event.numEquipos,
      costoActual: event.costoActual,
      totalInscritos: event.totalInscritos,
    ));
  }

  /// CA-006: Procesar edicion de fecha
  Future<void> _onEditarFecha(
    EditarFechaSubmitEvent event,
    Emitter<EditarFechaState> emit,
  ) async {
    // Validaciones frontend antes de enviar al backend

    // CA-005, RN-004: Validar fecha futura
    if (event.fechaHoraInicio.isBefore(DateTime.now())) {
      emit(const EditarFechaError(
        message: 'La fecha y hora deben ser futuras',
        hint: 'fecha_pasada',
      ));
      return;
    }

    // Validar duracion (1-5 horas)
    if (event.duracionHoras < 1.0 || event.duracionHoras > 5.0) {
      emit(const EditarFechaError(
        message: 'La duracion debe ser entre 1 y 5 horas',
        hint: 'duracion_invalida',
      ));
      return;
    }

    // Validar lugar minimo 3 caracteres
    if (event.lugar.trim().length < 3) {
      emit(const EditarFechaError(
        message: 'El lugar debe tener al menos 3 caracteres',
        hint: 'lugar_invalido',
      ));
      return;
    }

    // Validar numero de equipos (2-4)
    if (event.numEquipos < 2 || event.numEquipos > 4) {
      emit(const EditarFechaError(
        message: 'El numero de equipos debe ser entre 2 y 4',
        hint: 'equipos_invalido',
      ));
      return;
    }

    // Validar costo (0-100)
    if (event.costoPorJugador < 0 || event.costoPorJugador > 100) {
      emit(const EditarFechaError(
        message: 'El costo debe ser entre S/ 0.00 y S/ 100.00',
        hint: 'costo_invalido',
      ));
      return;
    }

    // Emitir estado de carga
    emit(const EditarFechaLoading());

    // Llamar al repositorio
    final result = await repository.editarFecha(
      fechaId: event.fechaId,
      fechaHoraInicio: event.fechaHoraInicio,
      duracionHoras: event.duracionHoras,
      lugar: event.lugar.trim(),
      numEquipos: event.numEquipos,
      costoPorJugador: event.costoPorJugador,
    );

    // Procesar resultado
    result.fold(
      (failure) {
        // Extraer datos del ServerFailure
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(EditarFechaError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        // CA-006: Exito - fecha editada
        if (response.success && response.data != null) {
          emit(EditarFechaSuccess(
            fecha: response.data!,
            message: response.message,
          ));
        } else {
          // Respuesta inesperada
          emit(const EditarFechaError(
            message: 'Error inesperado al editar la fecha',
          ));
        }
      },
    );
  }

  /// Reiniciar estado del formulario
  void _onReset(
    EditarFechaResetEvent event,
    Emitter<EditarFechaState> emit,
  ) {
    emit(const EditarFechaInitial());
  }
}

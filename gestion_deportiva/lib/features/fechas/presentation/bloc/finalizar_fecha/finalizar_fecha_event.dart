import 'package:equatable/equatable.dart';

/// Eventos del BLoC de finalizar fecha
/// E003-HU-010: Finalizar Fecha
abstract class FinalizarFechaEvent extends Equatable {
  const FinalizarFechaEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para finalizar una fecha de pichanga
/// CA-001 a CA-006: Submit de finalizacion con datos opcionales
class FinalizarFechaSubmitEvent extends FinalizarFechaEvent {
  /// ID de la fecha a finalizar
  final String fechaId;

  /// Comentarios u observaciones opcionales (CA-004)
  final String? comentarios;

  /// Flag que indica si hubo incidente (CA-005)
  final bool huboIncidente;

  /// Descripcion del incidente (obligatoria si huboIncidente es true) (CA-005)
  final String? descripcionIncidente;

  const FinalizarFechaSubmitEvent({
    required this.fechaId,
    this.comentarios,
    this.huboIncidente = false,
    this.descripcionIncidente,
  });

  @override
  List<Object?> get props => [
        fechaId,
        comentarios,
        huboIncidente,
        descripcionIncidente,
      ];
}

/// Evento para reiniciar el estado del BLoC
class FinalizarFechaResetEvent extends FinalizarFechaEvent {
  const FinalizarFechaResetEvent();
}

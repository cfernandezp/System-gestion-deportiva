import 'package:equatable/equatable.dart';

/// Eventos del BLoC de fechas disponibles
/// E003-HU-002: Inscribirse a Fecha
abstract class FechasDisponiblesEvent extends Equatable {
  const FechasDisponiblesEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar la lista de fechas disponibles
/// RN-002: Solo fechas con estado 'abierta'
class CargarFechasDisponiblesEvent extends FechasDisponiblesEvent {
  const CargarFechasDisponiblesEvent();
}

/// Evento para refrescar la lista de fechas
class RefrescarFechasDisponiblesEvent extends FechasDisponiblesEvent {
  const RefrescarFechasDisponiblesEvent();
}

/// Evento para reiniciar el estado del bloc
class ResetFechasDisponiblesEvent extends FechasDisponiblesEvent {
  const ResetFechasDisponiblesEvent();
}

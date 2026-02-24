import 'package:equatable/equatable.dart';

/// Estados del Bloc PromoverInvitado
/// E002-HU-009: Promover Invitado a Jugador
abstract class PromoverInvitadoState extends Equatable {
  const PromoverInvitadoState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PromoverInvitadoInitial extends PromoverInvitadoState {}

/// Promoviendo invitado (loading)
class PromoverInvitadoLoading extends PromoverInvitadoState {}

/// Invitado promovido exitosamente
class PromoverInvitadoSuccess extends PromoverInvitadoState {
  final String nombre;
  final String mensaje;

  const PromoverInvitadoSuccess({
    required this.nombre,
    required this.mensaje,
  });

  @override
  List<Object?> get props => [nombre, mensaje];
}

/// Error general al promover invitado
class PromoverInvitadoError extends PromoverInvitadoState {
  final String mensaje;
  final String? hint;

  const PromoverInvitadoError({
    required this.mensaje,
    this.hint,
  });

  @override
  List<Object?> get props => [mensaje, hint];
}

/// CA-003: Celular ya existe en el sistema (error especial con dialogo)
class PromoverInvitadoCelularExiste extends PromoverInvitadoState {
  final String mensaje;
  final String celular;

  const PromoverInvitadoCelularExiste({
    required this.mensaje,
    required this.celular,
  });

  @override
  List<Object?> get props => [mensaje, celular];
}

/// CA-007: Limite de jugadores alcanzado (error especial con dialogo)
class PromoverInvitadoLimiteAlcanzado extends PromoverInvitadoState {
  final String mensaje;

  const PromoverInvitadoLimiteAlcanzado({required this.mensaje});

  @override
  List<Object?> get props => [mensaje];
}

import 'package:equatable/equatable.dart';

/// Estados del Bloc RegistrarInvitado
/// E002-HU-008: Registrar Invitado en el Grupo
abstract class RegistrarInvitadoState extends Equatable {
  const RegistrarInvitadoState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class RegistrarInvitadoInitial extends RegistrarInvitadoState {}

/// Registrando invitado (loading)
class RegistrarInvitadoLoading extends RegistrarInvitadoState {}

/// Invitado registrado exitosamente
class RegistrarInvitadoSuccess extends RegistrarInvitadoState {
  final String nombre;
  final String mensaje;

  const RegistrarInvitadoSuccess({
    required this.nombre,
    required this.mensaje,
  });

  @override
  List<Object?> get props => [nombre, mensaje];
}

/// Error al registrar invitado
class RegistrarInvitadoError extends RegistrarInvitadoState {
  final String mensaje;
  final String? hint;

  const RegistrarInvitadoError({
    required this.mensaje,
    this.hint,
  });

  @override
  List<Object?> get props => [mensaje, hint];
}

/// Limite de invitados alcanzado (error especial con dialogo)
class RegistrarInvitadoLimiteAlcanzado extends RegistrarInvitadoState {
  final String mensaje;

  const RegistrarInvitadoLimiteAlcanzado({required this.mensaje});

  @override
  List<Object?> get props => [mensaje];
}

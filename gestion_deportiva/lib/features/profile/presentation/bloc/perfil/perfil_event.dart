import 'package:equatable/equatable.dart';

import '../../../data/models/perfil_model.dart';

/// Eventos del BLoC de Perfil
/// E002-HU-001: Ver Perfil Propio
/// E002-HU-002: Editar Perfil Propio
abstract class PerfilEvent extends Equatable {
  const PerfilEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar el perfil del usuario actual
/// CA-001: Acceso al perfil desde seccion "Mi Perfil"
class CargarPerfilEvent extends PerfilEvent {
  const CargarPerfilEvent();
}

/// Evento para refrescar el perfil (pull to refresh)
class RefrescarPerfilEvent extends PerfilEvent {
  const RefrescarPerfilEvent();
}

/// E002-HU-002: Evento para actualizar el perfil
/// CA-002: Campos editables: apodo, telefono, posicion, foto
/// CA-004: Guardar cambios con confirmacion
class ActualizarPerfilEvent extends PerfilEvent {
  final String apodo;
  final String? telefono;
  final PosicionJugador? posicionPreferida;
  final String? fotoUrl;

  const ActualizarPerfilEvent({
    required this.apodo,
    this.telefono,
    this.posicionPreferida,
    this.fotoUrl,
  });

  @override
  List<Object?> get props => [apodo, telefono, posicionPreferida, fotoUrl];
}

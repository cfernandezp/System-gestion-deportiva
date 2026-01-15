import 'package:equatable/equatable.dart';

/// Eventos del BLoC de Perfil
/// E002-HU-001: Ver Perfil Propio
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

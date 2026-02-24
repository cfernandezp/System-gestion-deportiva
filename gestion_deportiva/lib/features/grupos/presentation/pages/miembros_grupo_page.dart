import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../data/models/miembro_grupo_model.dart';
import '../bloc/miembros_grupo/miembros_grupo_bloc.dart';
import '../bloc/miembros_grupo/miembros_grupo_event.dart';
import '../bloc/miembros_grupo/miembros_grupo_state.dart';
import '../bloc/promover_invitado/promover_invitado_bloc.dart';
import '../bloc/promover_invitado/promover_invitado_event.dart';
import '../bloc/promover_invitado/promover_invitado_state.dart';
import '../bloc/registrar_invitado/registrar_invitado_bloc.dart';
import '../bloc/registrar_invitado/registrar_invitado_event.dart';
import '../bloc/registrar_invitado/registrar_invitado_state.dart';

/// E002-HU-005: Ver Miembros del Grupo
/// CA-001 a CA-005, RN-001 a RN-005
/// E002-HU-006: Eliminar Jugador del Grupo
/// E002-HU-004: Nombrar y Quitar Co-Administradores
/// E002-HU-008: Registrar Invitado en el Grupo
/// Patron mobile: ListView con Cards, busqueda, filtros por rol, privacidad celular
class MiembrosGrupoPage extends StatefulWidget {
  final String grupoId;
  final bool esAdminOCoadmin;
  final String miRol; // 'admin', 'coadmin', 'jugador', 'invitado'

  const MiembrosGrupoPage({
    super.key,
    required this.grupoId,
    required this.esAdminOCoadmin,
    this.miRol = 'jugador',
  });

  @override
  State<MiembrosGrupoPage> createState() => _MiembrosGrupoPageState();
}

class _MiembrosGrupoPageState extends State<MiembrosGrupoPage> {
  final _searchController = TextEditingController();

  /// RN-002: Celular del usuario actual para identificar "soy yo"
  String _currentUserPhone = '';

  @override
  void initState() {
    super.initState();
    // Obtener celular del usuario actual desde Supabase Auth
    final phone = Supabase.instance.client.auth.currentUser?.phone ?? '';
    // Normalizar: quitar prefijo +51 si existe (Peru)
    _currentUserPhone = phone.replaceFirst('+51', '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// RN-002: Determina si un miembro es el usuario actual
  bool _esMiembro(MiembroGrupoModel miembro) {
    return miembro.celular == _currentUserPhone;
  }

  /// RN-002: Determina si se muestra el celular completo
  /// Admin/coadmin ven todos los celulares completos
  /// Cada miembro ve su propio celular completo
  bool _mostrarCelularCompleto(MiembroGrupoModel miembro) {
    return widget.esAdminOCoadmin || _esMiembro(miembro);
  }

  /// E002-HU-006: Determina si se puede eliminar un miembro segun permisos
  bool _puedeEliminar(MiembroGrupoModel miembro) {
    // Solo admin/coadmin pueden eliminar (RN-001)
    if (!widget.esAdminOCoadmin) return false;
    // No te puedes eliminar a ti mismo
    if (_esMiembro(miembro)) return false;
    // RN-002: Admin creador (rol 'admin') NO puede ser eliminado
    if (miembro.rol == 'admin') return false;
    // RN-003: Coadmin solo puede eliminar jugadores e invitados
    if (widget.miRol == 'coadmin') {
      return miembro.rol == 'jugador' || miembro.rol == 'invitado';
    }
    // RN-004: Admin puede eliminar coadmins, jugadores e invitados
    return true;
  }

  /// E002-HU-004 CA-001/RN-003: Determina si se puede promover un miembro a co-admin
  /// Solo el admin creador puede, solo jugadores activos
  bool _puedePromover(MiembroGrupoModel miembro) {
    // RN-001: Solo admin creador puede gestionar co-admins
    if (widget.miRol != 'admin') return false;
    // No promover a ti mismo
    if (_esMiembro(miembro)) return false;
    // RN-003: Solo jugadores activos
    if (miembro.rol != 'jugador') return false;
    // No promover pendientes
    if (miembro.estaPendiente) return false;
    if (!miembro.activo) return false;
    return true;
  }

  /// E002-HU-004 CA-002: Determina si se puede degradar un co-admin
  /// Solo el admin creador puede
  bool _puedeDegrada(MiembroGrupoModel miembro) {
    // RN-001: Solo admin creador puede gestionar co-admins
    if (widget.miRol != 'admin') return false;
    // No degradar a ti mismo
    if (_esMiembro(miembro)) return false;
    // Solo degradar co-admins
    if (miembro.rol != 'coadmin') return false;
    return true;
  }

  /// E002-HU-004 CA-001/RN-006: Dialogo de confirmacion para promover a co-admin
  Future<void> _mostrarDialogoPromover(MiembroGrupoModel miembro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promover a Co-Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Promover a "${miembro.displayName}" como co-administrador?'),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Un co-administrador puede editar el grupo, gestionar miembros y crear fechas, pero NO puede eliminar el grupo ni gestionar otros co-admins.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Promover'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      context.read<MiembrosGrupoBloc>().add(PromoverACoadminEvent(
        grupoId: widget.grupoId,
        miembroId: miembro.miembroId,
        nombreJugador: miembro.displayName,
      ));
    }
  }

  /// E002-HU-004 CA-002/RN-006: Dialogo de confirmacion para degradar co-admin
  Future<void> _mostrarDialogoDegrada(MiembroGrupoModel miembro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar Co-Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quitar el rol de co-administrador a "${miembro.displayName}"?'),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'El miembro conservara su membresia en el grupo y pasara a ser jugador regular.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.accentColor,
            ),
            child: const Text('Quitar Co-Admin'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      context.read<MiembrosGrupoBloc>().add(DegradarCoadminEvent(
        grupoId: widget.grupoId,
        miembroId: miembro.miembroId,
        nombreJugador: miembro.displayName,
      ));
    }
  }

  /// E002-HU-006 CA-005/RN-006: Dialogo de confirmacion antes de eliminar jugador
  Future<void> _mostrarDialogoEliminar(MiembroGrupoModel miembro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar del grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Eliminar a "${miembro.displayName}" del grupo?'),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Esta accion eliminara al jugador de este grupo pero no afectara su cuenta ni su participacion en otros grupos.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.errorColor,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      context.read<MiembrosGrupoBloc>().add(EliminarJugadorEvent(
        grupoId: widget.grupoId,
        miembroId: miembro.miembroId,
        nombreJugador: miembro.displayName,
      ));
    }
  }

  /// E002-HU-008: Dialogo de confirmacion para eliminar invitado
  Future<void> _mostrarDialogoEliminarInvitado(MiembroGrupoModel miembro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar invitado del grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Eliminar a "${miembro.displayName}" del grupo?'),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'El invitado sera eliminado del grupo. Su historial de participacion en pichangas se conservara.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.errorColor,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      context.read<MiembrosGrupoBloc>().add(EliminarInvitadoEvent(
        grupoId: widget.grupoId,
        miembroId: miembro.miembroId,
        nombreInvitado: miembro.displayName,
      ));
    }
  }

  /// E002-HU-008: BottomSheet con opciones "Invitar Jugador" y "Agregar Invitado"
  void _mostrarOpcionesAgregar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusL)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle visual
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingM),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
                  child: Text(
                    'Agregar al grupo',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingM),
                // Opcion 1: Invitar Jugador (con cuenta)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: DesignTokens.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.person_add, color: DesignTokens.primaryColor),
                  ),
                  title: const Text('Invitar Jugador'),
                  subtitle: Text(
                    'Jugador con cuenta en la app',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    this.context.push('/grupos/${widget.grupoId}/invitar');
                  },
                ),
                const Divider(height: 1),
                // Opcion 2: Agregar Invitado (sin cuenta)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    child: const Icon(Icons.person_outline, color: Color(0xFF8B5CF6)),
                  ),
                  title: const Text('Agregar Invitado'),
                  subtitle: Text(
                    'Persona sin cuenta (solo nombre)',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _mostrarFormularioInvitado();
                  },
                ),
                const SizedBox(height: DesignTokens.spacingS),
              ],
            ),
          ),
        );
      },
    );
  }

  /// E002-HU-008: BottomSheet con formulario para registrar invitado
  void _mostrarFormularioInvitado() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusL)),
      ),
      builder: (bottomSheetContext) {
        return BlocProvider(
          create: (_) => sl<RegistrarInvitadoBloc>(),
          child: _FormularioInvitadoContent(
            grupoId: widget.grupoId,
            onSuccess: (nombre) {
              // Cerrar BottomSheet
              Navigator.of(bottomSheetContext).pop();
              // Mostrar SnackBar de exito
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$nombre" fue agregado como invitado'),
                    backgroundColor: DesignTokens.successColor,
                  ),
                );
                // Recargar lista de miembros
                context
                    .read<MiembrosGrupoBloc>()
                    .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId));
              }
            },
            onLimiteAlcanzado: (mensaje) {
              // Cerrar BottomSheet del formulario
              Navigator.of(bottomSheetContext).pop();
              // Mostrar AlertDialog de limite
              if (mounted) {
                _mostrarDialogoLimiteInvitados(mensaje);
              }
            },
          ),
        );
      },
    );
  }

  /// E002-HU-008: AlertDialog cuando se alcanza el limite de invitados
  void _mostrarDialogoLimiteInvitados(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: DesignTokens.accentColor,
              size: 48,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Limite de invitados alcanzado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              mensaje,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Puedes:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            Text(
              '  - Promover un invitado a jugador\n  - Eliminar un invitado existente\n  - Mejorar tu plan para mas invitados',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              this.context.push('/upgrade');
            },
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }

  /// E002-HU-009: BottomSheet con formulario de 2 pasos para promover invitado a jugador
  void _mostrarFormularioPromocion(MiembroGrupoModel miembro) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusL)),
      ),
      builder: (bottomSheetContext) {
        return BlocProvider(
          create: (_) => sl<PromoverInvitadoBloc>(),
          child: _FormularioPromocionContent(
            grupoId: widget.grupoId,
            miembro: miembro,
            onSuccess: (nombre) {
              // Cerrar BottomSheet
              Navigator.of(bottomSheetContext).pop();
              // Mostrar SnackBar de exito
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$nombre" fue promovido a jugador'),
                    backgroundColor: DesignTokens.successColor,
                  ),
                );
                // Recargar lista de miembros
                context
                    .read<MiembrosGrupoBloc>()
                    .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId));
              }
            },
            onCelularExiste: (celular, mensaje) {
              // Cerrar BottomSheet del formulario
              Navigator.of(bottomSheetContext).pop();
              // Mostrar AlertDialog de celular existente
              if (mounted) {
                _mostrarDialogoCelularExiste(celular, mensaje);
              }
            },
            onLimiteAlcanzado: (mensaje) {
              // Cerrar BottomSheet del formulario
              Navigator.of(bottomSheetContext).pop();
              // Mostrar AlertDialog de limite
              if (mounted) {
                _mostrarDialogoLimiteJugadores(mensaje);
              }
            },
          ),
        );
      },
    );
  }

  /// E002-HU-009 CA-003: AlertDialog cuando el celular ya existe en el sistema
  void _mostrarDialogoCelularExiste(String celular, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: DesignTokens.accentColor,
              size: 48,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Celular ya registrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'El numero $celular ya pertenece a un usuario registrado. Si esta persona quiere unirse a tu grupo, usa Invitar Jugador.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              this.context.push('/grupos/${widget.grupoId}/invitar');
            },
            child: const Text('Invitar Jugador'),
          ),
        ],
      ),
    );
  }

  /// E002-HU-009 CA-007: AlertDialog cuando se alcanza el limite de jugadores
  void _mostrarDialogoLimiteJugadores(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: DesignTokens.accentColor,
              size: 48,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Limite de jugadores alcanzado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              mensaje,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Puedes:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            Text(
              '  - Eliminar un jugador existente\n  - Mejorar tu plan para mas jugadores',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              this.context.push('/upgrade');
            },
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // MainShell: mobile = AppBottomNavBar, tablet = NavigationRail
    return MainShell(
      currentIndex: 2,
      appBar: AppBar(
        title: const Text('Miembros del Grupo'),
        centerTitle: true,
      ),
      floatingActionButton: widget.esAdminOCoadmin
          ? FloatingActionButton.extended(
              onPressed: _mostrarOpcionesAgregar,
              icon: const Icon(Icons.person_add),
              label: const Text('Agregar'),
            )
          : null,
      body: BlocConsumer<MiembrosGrupoBloc, MiembrosGrupoState>(
        listener: (context, state) {
          // E002-HU-006: Notificar exito y recargar miembros
          if (state is EliminarJugadorSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '"${state.nombreJugador}" fue eliminado del grupo',
                ),
                backgroundColor: DesignTokens.successColor,
              ),
            );
            // Recargar lista de miembros
            context
                .read<MiembrosGrupoBloc>()
                .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId));
          }

          // E002-HU-004 CA-001: Promover a co-admin exitoso
          if (state is PromoverCoadminSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '"${state.nombreJugador}" fue promovido a co-administrador',
                ),
                backgroundColor: DesignTokens.successColor,
              ),
            );
            // Recargar lista de miembros
            context
                .read<MiembrosGrupoBloc>()
                .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId));
          }

          // E002-HU-004 CA-002: Degradar co-admin exitoso
          if (state is DegradarCoadminSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '"${state.nombreJugador}" fue degradado a jugador',
                ),
                backgroundColor: DesignTokens.successColor,
              ),
            );
            // Recargar lista de miembros
            context
                .read<MiembrosGrupoBloc>()
                .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId));
          }

          // E002-HU-008: Invitado eliminado exitosamente
          if (state is EliminarInvitadoSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '"${state.nombreInvitado}" fue eliminado del grupo',
                ),
                backgroundColor: DesignTokens.successColor,
              ),
            );
            // Recargar lista de miembros
            context
                .read<MiembrosGrupoBloc>()
                .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId));
          }
        },
        builder: (context, state) {
          if (state is MiembrosGrupoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MiembrosGrupoError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                    const SizedBox(height: DesignTokens.spacingM),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: DesignTokens.spacingM),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<MiembrosGrupoBloc>()
                          .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is MiembrosGrupoLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<MiembrosGrupoBloc>()
                    .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId));
              },
              child: Column(
                children: [
                  // Header con conteo
                  _buildHeader(state, colorScheme, textTheme),

                  // CA-004 / RN-005: Barra de busqueda
                  _buildSearchBar(colorScheme),

                  // CA-003 / RN-004: Filtros por rol
                  _buildFilterChips(state, colorScheme),

                  // CA-005: Mensaje si es el unico miembro
                  if (state.esUnicoMiembro)
                    _buildSoloMemberMessage(colorScheme, textTheme),

                  // Lista de miembros filtrados
                  Expanded(
                    child: _buildMemberList(state, textTheme),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Header con conteo total y pendientes
  Widget _buildHeader(
    MiembrosGrupoLoaded state,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacingM,
        DesignTokens.spacingM,
        DesignTokens.spacingM,
        DesignTokens.spacingS,
      ),
      child: Row(
        children: [
          Icon(Icons.people, size: 20, color: colorScheme.primary),
          const SizedBox(width: DesignTokens.spacingS),
          Text(
            '${state.total} miembros',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          if (state.pendientes.isNotEmpty) ...[
            const SizedBox(width: DesignTokens.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Text(
                '${state.pendientes.length} pendientes',
                style: textTheme.labelSmall?.copyWith(
                  color: DesignTokens.accentColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// CA-004 / RN-005: Barra de busqueda por nombre
  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXs,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<MiembrosGrupoBloc>()
                        .add(const BuscarMiembroEvent(query: ''));
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: DesignTokens.spacingS,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        onChanged: (value) {
          context
              .read<MiembrosGrupoBloc>()
              .add(BuscarMiembroEvent(query: value));
          // Rebuild para mostrar/ocultar boton clear
          setState(() {});
        },
      ),
    );
  }

  /// CA-003 / RN-004: Chips de filtro por rol
  Widget _buildFilterChips(MiembrosGrupoLoaded state, ColorScheme colorScheme) {
    final roles = [
      {'value': 'admin', 'label': 'Admin'},
      {'value': 'coadmin', 'label': 'Co-Admin'},
      {'value': 'jugador', 'label': 'Jugador'},
      {'value': 'invitado', 'label': 'Invitado'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXs,
      ),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // Chip "Todos"
            Padding(
              padding: const EdgeInsets.only(right: DesignTokens.spacingS),
              child: FilterChip(
                label: const Text('Todos'),
                selected: state.filtroRol == null,
                onSelected: (_) {
                  context
                      .read<MiembrosGrupoBloc>()
                      .add(const FiltrarPorRolEvent());
                },
                selectedColor: colorScheme.primaryContainer,
                showCheckmark: false,
              ),
            ),
            // Chips por rol
            ...roles.map((rol) => Padding(
                  padding: const EdgeInsets.only(right: DesignTokens.spacingS),
                  child: FilterChip(
                    label: Text(rol['label']!),
                    selected: state.filtroRol == rol['value'],
                    onSelected: (_) {
                      final nuevoRol = state.filtroRol == rol['value']
                          ? null
                          : rol['value'];
                      context
                          .read<MiembrosGrupoBloc>()
                          .add(FiltrarPorRolEvent(rol: nuevoRol));
                    },
                    selectedColor: colorScheme.primaryContainer,
                    showCheckmark: false,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// CA-005: Mensaje cuando el admin es el unico miembro
  Widget _buildSoloMemberMessage(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              'Aun no hay otros miembros en el grupo. Invita jugadores para comenzar.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de miembros filtrados
  Widget _buildMemberList(MiembrosGrupoLoaded state, TextTheme textTheme) {
    final filtrados = state.miembrosFiltrados;

    // RN-004 / RN-005: Sin resultados con filtro o busqueda
    if (filtrados.isEmpty && state.tieneFiltrosActivos) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                state.busqueda.isNotEmpty
                    ? 'No se encontraron miembros con ese nombre'
                    : 'No hay miembros con el rol seleccionado',
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
      ),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final miembro = filtrados[index];
        // E002-HU-009: Determinar si se puede promover invitado
        final esInvitadoPromovible = miembro.rol == 'invitado' &&
            widget.miRol == 'admin' &&
            !_esMiembro(miembro);

        return _MiembroCard(
          miembro: miembro,
          mostrarCelularCompleto: _mostrarCelularCompleto(miembro),
          esAdminOCoadmin: widget.esAdminOCoadmin,
          miRol: widget.miRol,
          puedeEliminar: _puedeEliminar(miembro),
          puedePromover: _puedePromover(miembro),
          puedeDegrada: _puedeDegrada(miembro),
          esSiMismo: _esMiembro(miembro),
          onEliminar: _puedeEliminar(miembro)
              ? () {
                  if (miembro.rol == 'invitado') {
                    _mostrarDialogoEliminarInvitado(miembro);
                  } else {
                    _mostrarDialogoEliminar(miembro);
                  }
                }
              : null,
          onPromover: _puedePromover(miembro)
              ? () => _mostrarDialogoPromover(miembro)
              : null,
          onDegrada: _puedeDegrada(miembro)
              ? () => _mostrarDialogoDegrada(miembro)
              : null,
          onPromoverInvitado: esInvitadoPromovible
              ? () => _mostrarFormularioPromocion(miembro)
              : null,
        );
      },
    );
  }
}

/// E002-HU-008: Widget interno para el formulario de registrar invitado
/// Se usa dentro del BottomSheet con su propio BlocProvider
class _FormularioInvitadoContent extends StatefulWidget {
  final String grupoId;
  final void Function(String nombre) onSuccess;
  final void Function(String mensaje) onLimiteAlcanzado;

  const _FormularioInvitadoContent({
    required this.grupoId,
    required this.onSuccess,
    required this.onLimiteAlcanzado,
  });

  @override
  State<_FormularioInvitadoContent> createState() =>
      _FormularioInvitadoContentState();
}

class _FormularioInvitadoContentState
    extends State<_FormularioInvitadoContent> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<RegistrarInvitadoBloc, RegistrarInvitadoState>(
      listener: (context, state) {
        if (state is RegistrarInvitadoSuccess) {
          widget.onSuccess(state.nombre);
        }
        if (state is RegistrarInvitadoLimiteAlcanzado) {
          widget.onLimiteAlcanzado(state.mensaje);
        }
        if (state is RegistrarInvitadoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensaje),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: DesignTokens.spacingL,
          right: DesignTokens.spacingL,
          top: DesignTokens.spacingM,
          bottom: MediaQuery.of(context).viewInsets.bottom + DesignTokens.spacingL,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle visual
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingL),

              // Titulo
              Text(
                'Agregar Invitado',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXs),

              // Subtitulo
              Text(
                'Solo necesitas el nombre. El invitado no requiere cuenta en la app.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingL),

              // Campo de nombre
              TextFormField(
                controller: _nombreController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Nombre del invitado',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.trim().length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: DesignTokens.spacingL),

              // Boton de registrar
              BlocBuilder<RegistrarInvitadoBloc, RegistrarInvitadoState>(
                builder: (context, state) {
                  final isLoading = state is RegistrarInvitadoLoading;

                  return FilledButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              context.read<RegistrarInvitadoBloc>().add(
                                RegistrarInvitadoSubmitEvent(
                                  grupoId: widget.grupoId,
                                  nombre: _nombreController.text.trim(),
                                ),
                              );
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.spacingS,
                      ),
                      child: isLoading
                          ? const Text('Registrando...')
                          : const Text('Registrar Invitado'),
                    ),
                  );
                },
              ),
              const SizedBox(height: DesignTokens.spacingM),

              // Nota informativa
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingS),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        'El invitado podra participar en pichangas pero no aparecera en rankings del grupo.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// E002-HU-009: Widget interno para el formulario de promover invitado a jugador
/// BottomSheet con 2 pasos: formulario celular + confirmacion
/// Se usa dentro del BottomSheet con su propio BlocProvider
class _FormularioPromocionContent extends StatefulWidget {
  final String grupoId;
  final MiembroGrupoModel miembro;
  final void Function(String nombre) onSuccess;
  final void Function(String celular, String mensaje) onCelularExiste;
  final void Function(String mensaje) onLimiteAlcanzado;

  const _FormularioPromocionContent({
    required this.grupoId,
    required this.miembro,
    required this.onSuccess,
    required this.onCelularExiste,
    required this.onLimiteAlcanzado,
  });

  @override
  State<_FormularioPromocionContent> createState() =>
      _FormularioPromocionContentState();
}

class _FormularioPromocionContentState
    extends State<_FormularioPromocionContent> {
  final _formKey = GlobalKey<FormState>();
  final _celularController = TextEditingController();
  int _paso = 1;

  @override
  void dispose() {
    _celularController.dispose();
    super.dispose();
  }

  /// CA-002: Validacion de formato celular Peru
  String? _validateCelular(String? value) {
    if (value == null || value.isEmpty) {
      return 'El celular es obligatorio';
    }
    if (value.length != 9) {
      return 'Debe tener exactamente 9 digitos';
    }
    if (!value.startsWith('9')) {
      return 'Debe iniciar con el digito 9';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<PromoverInvitadoBloc, PromoverInvitadoState>(
      listener: (context, state) {
        if (state is PromoverInvitadoSuccess) {
          widget.onSuccess(state.nombre);
        }
        if (state is PromoverInvitadoCelularExiste) {
          widget.onCelularExiste(state.celular, state.mensaje);
        }
        if (state is PromoverInvitadoLimiteAlcanzado) {
          widget.onLimiteAlcanzado(state.mensaje);
        }
        if (state is PromoverInvitadoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensaje),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: DesignTokens.spacingL,
          right: DesignTokens.spacingL,
          top: DesignTokens.spacingM,
          bottom: MediaQuery.of(context).viewInsets.bottom + DesignTokens.spacingL,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _paso == 1
              ? _buildPaso1(colorScheme, textTheme)
              : _buildPaso2(colorScheme, textTheme),
        ),
      ),
    );
  }

  /// Paso 1: Formulario con campo de celular
  Widget _buildPaso1(ColorScheme colorScheme, TextTheme textTheme) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('paso1'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle visual
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Titulo
          Text(
            'Promover a Jugador',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),

          // Subtitulo
          Text(
            'Asigna un celular para que pueda activar su cuenta en la app.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Container info del invitado
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    child: Text(
                      widget.miembro.displayName.isNotEmpty
                          ? widget.miembro.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.miembro.displayName,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                      Text(
                        'Sin cuenta en la app',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Campo celular (patron de invitar_jugador_page.dart)
          TextFormField(
            controller: _celularController,
            keyboardType: TextInputType.phone,
            maxLength: 9,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: InputDecoration(
              labelText: 'Numero de celular',
              hintText: '9XXXXXXXX',
              prefixIcon: const Icon(Icons.phone_android),
              prefixText: '+51 ',
              counterText: '',
              helperText: 'Formato: 9 digitos, debe iniciar con 9',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
            ),
            validator: _validateCelular,
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Boton Continuar
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() => _paso = 2);
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
              child: Text('Continuar'),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),

          // Nota informativa
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Text(
                    'Debes avisarle al jugador por WhatsApp o en persona para que active su cuenta.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Paso 2: Confirmacion (CA-009)
  Widget _buildPaso2(ColorScheme colorScheme, TextTheme textTheme) {
    final celular = _celularController.text.trim();

    return Column(
      key: const ValueKey('paso2'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle visual
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingL),

        // Titulo
        Text(
          'Confirmar Promocion',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),

        // Subtitulo
        Text(
          'Revisa los datos antes de continuar.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingL),

        // Card con resumen
        Card(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Column(
              children: [
                _buildResumenRow(
                  textTheme,
                  colorScheme,
                  icon: Icons.person,
                  label: 'Nombre',
                  value: widget.miembro.displayName,
                ),
                const SizedBox(height: DesignTokens.spacingS),
                _buildResumenRow(
                  textTheme,
                  colorScheme,
                  icon: Icons.phone_android,
                  label: 'Celular',
                  value: '+51 $celular',
                ),
                const SizedBox(height: DesignTokens.spacingS),
                _buildResumenRow(
                  textTheme,
                  colorScheme,
                  icon: Icons.swap_horiz,
                  label: 'Cambio de rol',
                  value: 'Invitado \u2192 Jugador',
                ),
                const SizedBox(height: DesignTokens.spacingS),
                _buildResumenRow(
                  textTheme,
                  colorScheme,
                  icon: Icons.schedule,
                  label: 'Estado',
                  value: 'Pendiente de activacion',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),

        // Container informativo
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Al promover:',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXs),
              Text(
                '  \u2022 Su historial se conserva\n  \u2022 Libera un cupo de invitado\n  \u2022 Ocupa un cupo de jugador\n  \u2022 Podra activar su cuenta',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacingL),

        // Botones: Volver + Promover a Jugador
        BlocBuilder<PromoverInvitadoBloc, PromoverInvitadoState>(
          builder: (context, state) {
            final isLoading = state is PromoverInvitadoLoading;

            return Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: isLoading ? null : () => setState(() => _paso = 1),
                    child: const Text('Volver'),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            context.read<PromoverInvitadoBloc>().add(
                              PromoverInvitadoSubmitEvent(
                                grupoId: widget.grupoId,
                                miembroId: widget.miembro.miembroId,
                                celular: celular,
                              ),
                            );
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.spacingS,
                      ),
                      child: isLoading
                          ? const Text('Promoviendo...')
                          : const Text('Promover a Jugador'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Fila de resumen para el paso 2
  Widget _buildResumenRow(
    TextTheme textTheme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card de miembro individual
/// CA-001: Nombre, celular (con privacidad), rol, estado
/// CA-002: Admin/coadmin ven celular completo y estado detallado
/// E002-HU-006: Boton eliminar si tiene permisos
/// E002-HU-004: Opciones promover/degradar co-admin
/// E002-HU-008: Soporte para invitados (avatar con borde violeta, sin celular)
class _MiembroCard extends StatelessWidget {
  final MiembroGrupoModel miembro;
  final bool mostrarCelularCompleto;
  final bool esAdminOCoadmin;
  final String miRol;
  final bool puedeEliminar;
  final bool puedePromover;
  final bool puedeDegrada;
  final bool esSiMismo;
  final VoidCallback? onEliminar;
  final VoidCallback? onPromover;
  final VoidCallback? onDegrada;
  final VoidCallback? onPromoverInvitado;

  const _MiembroCard({
    required this.miembro,
    required this.mostrarCelularCompleto,
    required this.esAdminOCoadmin,
    this.miRol = 'jugador',
    this.puedeEliminar = false,
    this.puedePromover = false,
    this.puedeDegrada = false,
    this.esSiMismo = false,
    this.onEliminar,
    this.onPromover,
    this.onDegrada,
    this.onPromoverInvitado,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final esInvitado = miembro.rol == 'invitado';

    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: ListTile(
        leading: _buildAvatar(esInvitado),
        title: Text(
          miembro.displayName,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: DesignTokens.spacingXxs),
            // E002-HU-008: Invitados muestran "Sin cuenta en la app" en cursiva
            if (esInvitado)
              Text(
                'Sin cuenta en la app',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              // RN-002: Celular con privacidad segun rol
              Text(
                mostrarCelularCompleto
                    ? miembro.celular
                    : miembro.celularEnmascarado,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: DesignTokens.spacingXs),
            // Rol badge + estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingXs,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: _getRolColor(miembro.rol).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                  ),
                  child: Text(
                    miembro.rolFormateado,
                    style: textTheme.labelSmall?.copyWith(
                      color: _getRolColor(miembro.rol),
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  miembro.estadoFormateado,
                  style: textTheme.labelSmall?.copyWith(
                    color: miembro.estaPendiente
                        ? DesignTokens.accentColor
                        : DesignTokens.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: esAdminOCoadmin
            ? _buildPopupMenu(context)
            : miembro.estaPendiente
                ? const Icon(
                    Icons.schedule,
                    size: DesignTokens.iconSizeS,
                    color: DesignTokens.accentColor,
                  )
                : const Icon(
                    Icons.check_circle,
                    size: DesignTokens.iconSizeS,
                    color: DesignTokens.successColor,
                  ),
      ),
    );
  }

  /// E002-HU-008: Avatar con borde violeta sutil para invitados
  Widget _buildAvatar(bool esInvitado) {
    final avatar = CircleAvatar(
      backgroundColor: _getRolColor(miembro.rol).withValues(alpha: 0.1),
      backgroundImage: miembro.fotoUrl != null
          ? NetworkImage(miembro.fotoUrl!)
          : null,
      child: miembro.fotoUrl == null
          ? Text(
              miembro.displayName.isNotEmpty
                  ? miembro.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: _getRolColor(miembro.rol),
                fontWeight: DesignTokens.fontWeightBold,
              ),
            )
          : null,
    );

    if (esInvitado) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: avatar,
      );
    }

    return avatar;
  }

  /// PopupMenuButton con acciones de admin/coadmin sobre el miembro
  /// E002-HU-004: Incluye promover/degradar co-admin (solo para admin creador)
  /// E002-HU-008: Incluye promover invitado a jugador y eliminar invitado
  Widget _buildPopupMenu(BuildContext context) {
    final esInvitado = miembro.rol == 'invitado';

    // E002-HU-008: "Generar codigo" NO debe aparecer para invitados
    final mostrarGenerarCodigo =
        miembro.rol != 'admin' && miembro.rol != 'invitado' && !esSiMismo;
    final mostrarEliminar = puedeEliminar;
    final mostrarPromover = puedePromover;
    final mostrarDegrada = puedeDegrada;
    // E002-HU-008/E002-HU-009: "Promover a Jugador" solo para invitados, solo admin
    final mostrarPromoverInvitado = esInvitado && miRol == 'admin' && !esSiMismo;

    // Si no hay acciones disponibles, mostrar icono de estado
    if (!mostrarGenerarCodigo &&
        !mostrarEliminar &&
        !mostrarPromover &&
        !mostrarDegrada &&
        !mostrarPromoverInvitado) {
      return miembro.estaPendiente
          ? const Icon(
              Icons.schedule,
              size: DesignTokens.iconSizeS,
              color: DesignTokens.accentColor,
            )
          : const Icon(
              Icons.check_circle,
              size: DesignTokens.iconSizeS,
              color: DesignTokens.successColor,
            );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'generar_codigo':
            context.push(
              '/admin/generar-codigo-recuperacion',
              extra: miembro.celular,
            );
            break;
          case 'promover':
            onPromover?.call();
            break;
          case 'degradar':
            onDegrada?.call();
            break;
          case 'eliminar':
            onEliminar?.call();
            break;
          case 'promover_invitado':
            // E002-HU-009: Abrir BottomSheet de promocion
            onPromoverInvitado?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        // E002-HU-004 CA-001: Promover jugador a co-admin
        if (mostrarPromover)
          PopupMenuItem<String>(
            value: 'promover',
            child: ListTile(
              leading: Icon(
                Icons.admin_panel_settings_outlined,
                color: DesignTokens.secondaryColor,
              ),
              title: Text(
                'Promover a Co-Admin',
                style: TextStyle(color: DesignTokens.secondaryColor),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        // E002-HU-004 CA-002: Degradar co-admin a jugador
        if (mostrarDegrada)
          PopupMenuItem<String>(
            value: 'degradar',
            child: ListTile(
              leading: Icon(
                Icons.person_remove_outlined,
                color: DesignTokens.accentColor,
              ),
              title: Text(
                'Quitar Co-Admin',
                style: TextStyle(color: DesignTokens.accentColor),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        // E002-HU-008/E002-HU-009: Promover invitado a jugador (solo admin)
        if (mostrarPromoverInvitado)
          const PopupMenuItem<String>(
            value: 'promover_invitado',
            child: ListTile(
              leading: Icon(Icons.upgrade_outlined, color: Color(0xFF8B5CF6)),
              title: Text(
                'Promover a Jugador',
                style: TextStyle(color: Color(0xFF8B5CF6)),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (mostrarGenerarCodigo)
          const PopupMenuItem<String>(
            value: 'generar_codigo',
            child: ListTile(
              leading: Icon(Icons.vpn_key_outlined),
              title: Text('Generar codigo de recuperacion'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (mostrarEliminar)
          PopupMenuItem<String>(
            value: 'eliminar',
            child: ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: DesignTokens.errorColor,
              ),
              title: Text(
                'Eliminar del grupo',
                style: TextStyle(color: DesignTokens.errorColor),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Color _getRolColor(String rol) {
    switch (rol) {
      case 'admin':
        return DesignTokens.secondaryColor;
      case 'coadmin':
        return DesignTokens.accentColor;
      case 'jugador':
        return DesignTokens.primaryColor;
      case 'invitado':
        return const Color(0xFF8B5CF6);
      default:
        return DesignTokens.primaryColor;
    }
  }
}

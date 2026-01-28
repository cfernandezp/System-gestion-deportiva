import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/bloc/session/session.dart';
import '../../data/models/fecha_detalle_model.dart';
import '../../data/models/fecha_model.dart';
import '../bloc/inscripcion/inscripcion.dart';
import '../bloc/mi_equipo/mi_equipo.dart';
import '../widgets/widgets.dart';

/// Pagina de detalle de fecha con opcion de inscripcion y edicion
/// E003-HU-002: Inscribirse a Fecha
/// CA-001: Mostrar todos los detalles de la fecha
/// CA-002: Boton "Anotarme" visible cuando no esta inscrito
/// CA-003: Dialogo de confirmacion al presionar "Anotarme"
/// CA-004: Indicador "Ya estas anotado" cuando inscrito
/// CA-005: Mensaje "Inscripciones cerradas" si fecha no es abierta
/// CA-006: Lista de jugadores inscritos con contador
///
/// E003-HU-003: Ver Inscritos (Integrado)
/// CA-001: Acceso a lista de inscritos
/// CA-002: Informacion de cada inscrito (foto, apodo, posicion)
/// CA-003: Header con contador
/// CA-004: Estado vacio
/// CA-005: Indicador "(Tu)" para usuario actual
/// CA-006: Actualizacion en tiempo real
///
/// E003-HU-004: Cerrar Inscripciones
/// CA-001: Boton "Cerrar inscripciones" visible para admin si estado = 'abierta'
/// CA-006: Boton "Reabrir inscripciones" visible para admin si estado = 'cerrada'
///
/// E003-HU-008: Editar Fecha
/// CA-001: Boton "Editar" solo visible para admin
/// CA-002: Solo habilitado si fecha estado = 'abierta'
/// Usa ResponsiveLayout: Mobile App Style + Desktop Dashboard Style
class FechaDetallePage extends StatelessWidget {
  /// ID de la fecha a mostrar
  final String fechaId;

  const FechaDetallePage({
    super.key,
    required this.fechaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InscripcionBloc, InscripcionState>(
      listener: (context, state) {
        // CA-003: Mensaje de exito al inscribirse
        if (state is InscripcionExitosa) {
          _mostrarSnackBarExito(
            context,
            state.message.isNotEmpty
                ? state.message
                : 'Te anotaste para la pichanga',
          );
          // Recargar detalle para actualizar lista
          if (state.fechaDetalle != null) {
            // El estado ya tiene la fecha actualizada
          }
        }

        // CA-004: Mensaje de exito al cancelar
        if (state is CancelacionExitosa) {
          _mostrarSnackBarExito(
            context,
            state.message.isNotEmpty
                ? state.message
                : 'Has cancelado tu inscripcion. La deuda ha sido anulada.',
          );
        }

        // Error
        if (state is InscripcionError) {
          _mostrarSnackBarError(context, state.message);
        }
      },
      builder: (context, state) {
        // Obtener datos del estado
        final fechaDetalle = _obtenerFechaDetalle(state);
        final isLoading = state is InscripcionLoading;
        final isProcesando = state is InscripcionProcesando;
        final hasError = state is InscripcionError && fechaDetalle == null;
        final errorMessage = hasError ? state.message : null;

        // Siempre mostrar el layout, el loading/error va dentro del contenido
        return ResponsiveLayout(
          mobileBody: _MobileDetalleView(
            fechaId: fechaId,
            fechaDetalle: fechaDetalle,
            isLoading: isLoading,
            isProcesando: isProcesando,
            hasError: hasError,
            errorMessage: errorMessage,
          ),
          desktopBody: _DesktopDetalleView(
            fechaId: fechaId,
            fechaDetalle: fechaDetalle,
            isLoading: isLoading,
            isProcesando: isProcesando,
            hasError: hasError,
            errorMessage: errorMessage,
          ),
        );
      },
    );
  }

  FechaDetalleModel? _obtenerFechaDetalle(InscripcionState state) {
    if (state is InscripcionFechaDetalleCargado) return state.fechaDetalle;
    if (state is InscripcionProcesando) return state.fechaDetalle;
    if (state is InscripcionExitosa) return state.fechaDetalle;
    if (state is CancelacionExitosa) return state.fechaDetalle;
    if (state is InscripcionError) return state.fechaDetalle;
    return null;
  }

  void _mostrarSnackBarExito(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: DesignTokens.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarSnackBarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: DesignTokens.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================
// VISTA MOBILE - App Style
// ============================================

class _MobileDetalleView extends StatelessWidget {
  final String fechaId;
  final FechaDetalleModel? fechaDetalle;
  final bool isLoading;
  final bool isProcesando;
  final bool hasError;
  final String? errorMessage;

  const _MobileDetalleView({
    required this.fechaId,
    this.fechaDetalle,
    required this.isLoading,
    required this.isProcesando,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Pichanga'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // E003-HU-005: Boton "Asignar Equipos" visible para admin si estado = 'cerrada'
          if (fechaDetalle != null)
            _buildAsignarEquiposButton(context),
          // E003-HU-004 CA-001/CA-006: Boton cerrar/reabrir inscripciones (admin)
          if (fechaDetalle != null)
            _buildCerrarReabrirButton(context),
          // E003-HU-008 CA-001: Boton "Editar" solo visible para admin
          if (fechaDetalle != null)
            _buildEditarButton(context),
        ],
      ),
      body: _buildContent(context),
      bottomNavigationBar: fechaDetalle != null
          ? _buildBottomBar(context)
          : null,
    );
  }

  /// E003-HU-005: Boton para asignar equipos
  /// Solo visible para admin si estado = 'cerrada'
  Widget _buildAsignarEquiposButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        // Solo mostrar si es admin
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final isAdmin = sessionState.rol.toLowerCase() == 'admin' ||
            sessionState.rol.toLowerCase() == 'administrador';

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        final estado = fechaDetalle!.fecha.estado;

        // Solo mostrar si estado = 'cerrada'
        if (estado != EstadoFecha.cerrada) {
          return const SizedBox.shrink();
        }

        return IconButton(
          onPressed: () => context.go('/fechas/$fechaId/equipos'),
          icon: Icon(
            Icons.groups,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: 'Asignar equipos',
        );
      },
    );
  }

  /// E003-HU-004: Boton cerrar/reabrir inscripciones para admin
  /// CA-001: Solo visible para admin si estado = 'abierta'
  /// CA-006: Solo visible para admin si estado = 'cerrada'
  Widget _buildCerrarReabrirButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        // Solo mostrar si es admin
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final isAdmin = sessionState.rol.toLowerCase() == 'admin' ||
            sessionState.rol.toLowerCase() == 'administrador';

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        final estado = fechaDetalle!.fecha.estado;

        // CA-001: Si estado = 'abierta', mostrar "Cerrar inscripciones"
        if (estado == EstadoFecha.abierta) {
          return IconButton(
            onPressed: () => _abrirCerrarInscripcionesDialog(context),
            icon: Icon(
              Icons.lock,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Cerrar inscripciones',
          );
        }

        // CA-006: Si estado = 'cerrada', mostrar "Reabrir inscripciones"
        if (estado == EstadoFecha.cerrada) {
          return IconButton(
            onPressed: () => _abrirReabrirInscripcionesDialog(context),
            icon: Icon(
              Icons.lock_open,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Reabrir inscripciones',
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Abre el dialog de cerrar inscripciones
  void _abrirCerrarInscripcionesDialog(BuildContext context) {
    CerrarInscripcionesDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de cerrar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// Abre el dialog de reabrir inscripciones
  void _abrirReabrirInscripcionesDialog(BuildContext context) {
    ReabrirInscripcionesDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de reabrir
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// E003-HU-008: Boton de editar para admin
  /// CA-001: Solo visible para admin
  /// CA-002: Solo habilitado si fecha estado = 'abierta'
  Widget _buildEditarButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        // CA-001: Solo mostrar si es admin
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final isAdmin = sessionState.rol.toLowerCase() == 'admin' ||
            sessionState.rol.toLowerCase() == 'administrador';

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        // CA-002: Verificar si la fecha es editable
        final esEditable = fechaDetalle!.fecha.estado == EstadoFecha.abierta;

        return IconButton(
          onPressed: esEditable
              ? () => _abrirDialogoEditar(context)
              : () => _mostrarMensajeNoEditable(context),
          icon: Icon(
            Icons.edit,
            color: esEditable
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          tooltip: esEditable
              ? 'Editar fecha'
              : 'No se puede editar (${fechaDetalle!.fecha.estado.displayName})',
        );
      },
    );
  }

  /// Abre el dialogo de edicion
  void _abrirDialogoEditar(BuildContext context) {
    EditarFechaDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de editar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// Muestra mensaje cuando la fecha no es editable
  void _mostrarMensajeNoEditable(BuildContext context) {
    final estado = fechaDetalle!.fecha.estado;
    String mensaje;

    switch (estado) {
      case EstadoFecha.cerrada:
        mensaje = 'No se puede editar: las inscripciones estan cerradas.';
        break;
      case EstadoFecha.enJuego:
        mensaje = 'No se puede editar: la pichanga esta en curso.';
        break;
      case EstadoFecha.finalizada:
        mensaje = 'No se puede editar: la pichanga ya termino.';
        break;
      case EstadoFecha.cancelada:
        mensaje = 'No se puede editar: la pichanga fue cancelada.';
        break;
      default:
        mensaje = 'No se puede editar esta fecha.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Estado de carga
    if (isLoading && fechaDetalle == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && fechaDetalle == null) {
      return _buildErrorContent(context);
    }

    // Sin datos
    if (fechaDetalle == null) {
      return const Center(child: Text('No se encontro la fecha'));
    }

    // Contenido con datos
    return RefreshIndicator(
      onRefresh: () async {
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de informacion principal
            _buildInfoCard(context),

            const SizedBox(height: DesignTokens.spacingM),

            // E003-HU-003: Lista de inscritos con realtime
            // CA-001 a CA-006: Widget dedicado con BLoC propio
            InscritosListWidget(
              fechaId: fechaId,
              habilitarRealtime: true,
              capacidadMaxima: fechaDetalle!.capacidadMaxima > 0
                  ? fechaDetalle!.capacidadMaxima
                  : null,
            ),

            const SizedBox(height: DesignTokens.spacingM),

            // E003-HU-006: Ver Mi Equipo
            // CA-001 a CA-007: Widget para ver equipo asignado
            BlocProvider(
              create: (context) => MiEquipoBloc(
                repository: sl(),
                supabase: sl(),
              ),
              child: MiEquipoWidget(
                fechaId: fechaId,
                habilitarRealtime: true,
              ),
            ),

            const SizedBox(height: DesignTokens.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fecha = fechaDetalle!.fecha;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha y hora
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: colorScheme.primary,
                    size: DesignTokens.iconSizeL,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${fecha.fechaFormato} - ${fecha.horaFormato.isNotEmpty ? fecha.horaFormato : "Por definir"}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      Text(
                        '${fecha.duracionHoras} hora${fecha.duracionHoras != 1 ? 's' : ''} de juego',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildEstadoBadge(context),
              ],
            ),

            const Divider(height: DesignTokens.spacingL * 2),

            // Lugar
            _buildInfoRow(
              context,
              icon: Icons.location_on,
              label: 'Lugar',
              value: fecha.lugar,
            ),

            const SizedBox(height: DesignTokens.spacingM),

            // Formato
            _buildInfoRow(
              context,
              icon: Icons.groups,
              label: 'Formato',
              value: fecha.formatoJuego,
            ),

            const SizedBox(height: DesignTokens.spacingM),

            // Costo - CA-001: Mostrar costo a pagar
            _buildInfoRow(
              context,
              icon: Icons.attach_money,
              label: 'Debes pagar',
              value: fecha.costoFormato,
              destacado: true,
            ),

            const SizedBox(height: DesignTokens.spacingM),

            // Organizador
            _buildInfoRow(
              context,
              icon: Icons.person,
              label: 'Organizado por',
              value: fecha.createdByNombre,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // CA-004: Badge "Ya estas anotado" si inscrito
    if (fechaDetalle!.usuarioInscrito) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          border: Border.all(
            color: DesignTokens.successColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: DesignTokens.iconSizeS,
              color: DesignTokens.successColor,
            ),
            const SizedBox(width: DesignTokens.spacingXs),
            Text(
              'Anotado',
              style: textTheme.labelMedium?.copyWith(
                color: DesignTokens.successColor,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
          ],
        ),
      );
    }

    // CA-005: Badge de estado si inscripciones cerradas
    if (!fechaDetalle!.inscripcionesAbiertas) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        ),
        child: Text(
          fechaDetalle!.fecha.estado.displayName,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.error,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
      );
    }

    // Badge "Abierta"
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(
        'Abierta',
        style: textTheme.labelMedium?.copyWith(
          color: DesignTokens.successColor,
          fontWeight: DesignTokens.fontWeightMedium,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool destacado = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeM,
          color: destacado ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: destacado
                      ? DesignTokens.fontWeightBold
                      : DesignTokens.fontWeightMedium,
                  color: destacado ? colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Barra inferior con botones de accion
  Widget _buildBottomBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildActionButton(context),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // CA-005: Inscripciones cerradas
    if (!fechaDetalle!.inscripcionesAbiertas) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              color: colorScheme.error,
              size: DesignTokens.iconSizeM,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            Text(
              'Inscripciones cerradas',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
      );
    }

    // CA-004: Ya inscrito - mostrar boton cancelar
    if (fechaDetalle!.usuarioInscrito) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador "Ya estas anotado"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: DesignTokens.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: DesignTokens.successColor,
                  size: DesignTokens.iconSizeM,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Ya estas anotado',
                  style: textTheme.bodyLarge?.copyWith(
                    color: DesignTokens.successColor,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          // Boton cancelar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isProcesando
                  ? null
                  : () => _confirmarCancelacion(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
                padding: const EdgeInsets.all(DesignTokens.spacingM),
              ),
              icon: isProcesando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close),
              label: const Text('Cancelar inscripcion'),
            ),
          ),
        ],
      );
    }

    // CA-002: Boton "Anotarme"
    if (fechaDetalle!.puedeInscribirse) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isProcesando
              ? null
              : () => _confirmarInscripcion(context),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
          ),
          icon: isProcesando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.sports_soccer),
          label: const Text('Anotarme'),
        ),
      );
    }

    // Fecha llena
    if (fechaDetalle!.estaLleno) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: DesignTokens.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group,
              color: DesignTokens.accentColor,
              size: DesignTokens.iconSizeM,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            Text(
              'Fecha completa',
              style: textTheme.bodyLarge?.copyWith(
                color: DesignTokens.accentColor,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// CA-003: Dialogo de confirmacion para inscribirse
  void _confirmarInscripcion(BuildContext context) {
    final fecha = fechaDetalle!.fecha;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.sports_soccer,
          color: Theme.of(context).colorScheme.primary,
          size: 48,
        ),
        title: const Text('Confirmar inscripcion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Te anotaras para la pichanga:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _DialogInfoRow(icon: Icons.calendar_today, text: '${fecha.fechaFormato} - ${fecha.horaFormato}'),
            _DialogInfoRow(icon: Icons.location_on, text: fecha.lugar),
            _DialogInfoRow(
              icon: Icons.attach_money,
              text: 'Debes pagar: ${fecha.costoFormato}',
              destacado: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<InscripcionBloc>().add(
                InscribirseEvent(fechaId: fechaId),
              );
            },
            child: const Text('Anotarme'),
          ),
        ],
      ),
    );
  }

  /// E003-HU-007: Dialogo de confirmacion para cancelar inscripcion
  /// CA-001: Visible solo si usuario esta inscrito
  /// CA-002: Mensaje de confirmacion
  /// CA-005: Si fecha cerrada, mostrar mensaje
  void _confirmarCancelacion(BuildContext context) {
    CancelarInscripcionDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de cancelar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              errorMessage ?? 'Error al cargar detalle de la fecha',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            FilledButton.icon(
              onPressed: () {
                context.read<InscripcionBloc>().add(
                  CargarFechaDetalleEvent(fechaId: fechaId),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// VISTA DESKTOP - Dashboard Style
// ============================================

class _DesktopDetalleView extends StatelessWidget {
  final String fechaId;
  final FechaDetalleModel? fechaDetalle;
  final bool isLoading;
  final bool isProcesando;
  final bool hasError;
  final String? errorMessage;

  const _DesktopDetalleView({
    required this.fechaId,
    this.fechaDetalle,
    required this.isLoading,
    required this.isProcesando,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/fechas/$fechaId',
      title: 'Detalle de Pichanga',
      breadcrumbs: const ['Inicio', 'Fechas', 'Detalle'],
      actions: [
        // E003-HU-005: Boton "Asignar Equipos" visible para admin si estado = 'cerrada'
        if (fechaDetalle != null)
          _buildAsignarEquiposButton(context),
        // E003-HU-004 CA-001/CA-006: Boton cerrar/reabrir inscripciones (admin)
        if (fechaDetalle != null)
          _buildCerrarReabrirButton(context),
        // E003-HU-008 CA-001: Boton "Editar" solo visible para admin
        if (fechaDetalle != null)
          _buildEditarButton(context),
        OutlinedButton.icon(
          onPressed: () {
            context.read<InscripcionBloc>().add(
              CargarFechaDetalleEvent(fechaId: fechaId),
            );
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        OutlinedButton.icon(
          onPressed: () => context.go('/fechas'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver'),
        ),
      ],
      child: _buildContent(context),
    );
  }

  /// E003-HU-005: Boton para asignar equipos (Desktop)
  /// Solo visible para admin si estado = 'cerrada'
  Widget _buildAsignarEquiposButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        // Solo mostrar si es admin
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final isAdmin = sessionState.rol.toLowerCase() == 'admin' ||
            sessionState.rol.toLowerCase() == 'administrador';

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        final estado = fechaDetalle!.fecha.estado;

        // Solo mostrar si estado = 'cerrada'
        if (estado != EstadoFecha.cerrada) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(right: DesignTokens.spacingS),
          child: FilledButton.icon(
            onPressed: () => context.go('/fechas/$fechaId/equipos'),
            icon: const Icon(Icons.groups),
            label: const Text('Asignar Equipos'),
          ),
        );
      },
    );
  }

  /// E003-HU-004: Boton cerrar/reabrir inscripciones para admin (Desktop)
  /// CA-001: Solo visible para admin si estado = 'abierta'
  /// CA-006: Solo visible para admin si estado = 'cerrada'
  Widget _buildCerrarReabrirButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        // Solo mostrar si es admin
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final isAdmin = sessionState.rol.toLowerCase() == 'admin' ||
            sessionState.rol.toLowerCase() == 'administrador';

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        final estado = fechaDetalle!.fecha.estado;

        // CA-001: Si estado = 'abierta', mostrar "Cerrar inscripciones"
        if (estado == EstadoFecha.abierta) {
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.spacingS),
            child: FilledButton.icon(
              onPressed: () => _abrirCerrarInscripcionesDialog(context),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              icon: const Icon(Icons.lock),
              label: const Text('Cerrar Inscripciones'),
            ),
          );
        }

        // CA-006: Si estado = 'cerrada', mostrar "Reabrir inscripciones"
        if (estado == EstadoFecha.cerrada) {
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.spacingS),
            child: FilledButton.icon(
              onPressed: () => _abrirReabrirInscripcionesDialog(context),
              icon: const Icon(Icons.lock_open),
              label: const Text('Reabrir Inscripciones'),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Abre el dialog de cerrar inscripciones
  void _abrirCerrarInscripcionesDialog(BuildContext context) {
    CerrarInscripcionesDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de cerrar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// Abre el dialog de reabrir inscripciones
  void _abrirReabrirInscripcionesDialog(BuildContext context) {
    ReabrirInscripcionesDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de reabrir
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// E003-HU-008: Boton de editar para admin (Desktop)
  /// CA-001: Solo visible para admin
  /// CA-002: Solo habilitado si fecha estado = 'abierta'
  Widget _buildEditarButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        // CA-001: Solo mostrar si es admin
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final isAdmin = sessionState.rol.toLowerCase() == 'admin' ||
            sessionState.rol.toLowerCase() == 'administrador';

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        // CA-002: Verificar si la fecha es editable
        final esEditable = fechaDetalle!.fecha.estado == EstadoFecha.abierta;

        return Padding(
          padding: const EdgeInsets.only(right: DesignTokens.spacingS),
          child: esEditable
              ? FilledButton.icon(
                  onPressed: () => _abrirDialogoEditar(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar Fecha'),
                )
              : OutlinedButton.icon(
                  onPressed: () => _mostrarMensajeNoEditable(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  icon: const Icon(Icons.edit_off),
                  label: Text('No editable (${fechaDetalle!.fecha.estado.displayName})'),
                ),
        );
      },
    );
  }

  /// Abre el dialogo de edicion
  void _abrirDialogoEditar(BuildContext context) {
    EditarFechaDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de editar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// Muestra mensaje cuando la fecha no es editable
  void _mostrarMensajeNoEditable(BuildContext context) {
    final estado = fechaDetalle!.fecha.estado;
    String mensaje;

    switch (estado) {
      case EstadoFecha.cerrada:
        mensaje = 'No se puede editar: las inscripciones estan cerradas.';
        break;
      case EstadoFecha.enJuego:
        mensaje = 'No se puede editar: la pichanga esta en curso.';
        break;
      case EstadoFecha.finalizada:
        mensaje = 'No se puede editar: la pichanga ya termino.';
        break;
      case EstadoFecha.cancelada:
        mensaje = 'No se puede editar: la pichanga fue cancelada.';
        break;
      default:
        mensaje = 'No se puede editar esta fecha.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Estado de carga
    if (isLoading && fechaDetalle == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && fechaDetalle == null) {
      return _buildErrorContent(context);
    }

    // Sin datos
    if (fechaDetalle == null) {
      return const Center(child: Text('No se encontro la fecha'));
    }

    // Layout de 2 columnas para desktop
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda: Info principal + Accion
          SizedBox(
            width: 400,
            child: Column(
              children: [
                _buildInfoCard(context),
                const SizedBox(height: DesignTokens.spacingM),
                _buildActionCard(context),
              ],
            ),
          ),

          const SizedBox(width: DesignTokens.spacingL),

          // Columna derecha: Lista de inscritos + Mi Equipo
          Expanded(
            child: Column(
              children: [
                // E003-HU-003: Widget dedicado con BLoC propio y realtime
                InscritosListWidget(
                  fechaId: fechaId,
                  habilitarRealtime: true,
                  expandible: false, // En desktop, siempre expandido
                  capacidadMaxima: fechaDetalle!.capacidadMaxima > 0
                      ? fechaDetalle!.capacidadMaxima
                      : null,
                ),

                const SizedBox(height: DesignTokens.spacingM),

                // E003-HU-006: Ver Mi Equipo
                // CA-001 a CA-007: Widget para ver equipo asignado
                BlocProvider(
                  create: (context) => MiEquipoBloc(
                    repository: sl(),
                    supabase: sl(),
                  ),
                  child: MiEquipoWidget(
                    fechaId: fechaId,
                    habilitarRealtime: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fecha = fechaDetalle!.fecha;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con fecha y estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    gradient: DesignTokens.primaryGradient,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: DesignTokens.iconSizeL,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${fecha.fechaFormato} - ${fecha.horaFormato.isNotEmpty ? fecha.horaFormato : "Por definir"}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingXs),
                      Text(
                        '${fecha.duracionHoras} hora${fecha.duracionHoras != 1 ? 's' : ''} de juego',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: DesignTokens.spacingL),

            // Estado badge
            _buildEstadoBadge(context),

            const Divider(height: DesignTokens.spacingL * 2),

            // Detalles
            _buildDetailItem(
              context,
              icon: Icons.location_on,
              label: 'Lugar',
              value: fecha.lugar,
            ),
            const SizedBox(height: DesignTokens.spacingM),

            _buildDetailItem(
              context,
              icon: Icons.groups,
              label: 'Formato',
              value: fecha.formatoJuego,
            ),
            const SizedBox(height: DesignTokens.spacingM),

            _buildDetailItem(
              context,
              icon: Icons.attach_money,
              label: 'Debes pagar',
              value: fecha.costoFormato,
              destacado: true,
            ),
            const SizedBox(height: DesignTokens.spacingM),

            _buildDetailItem(
              context,
              icon: Icons.person,
              label: 'Organizado por',
              value: fecha.createdByNombre,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    if (fechaDetalle!.usuarioInscrito) {
      badgeColor = DesignTokens.successColor;
      badgeIcon = Icons.check_circle;
      badgeText = 'Ya estas anotado';
    } else if (!fechaDetalle!.inscripcionesAbiertas) {
      badgeColor = colorScheme.error;
      badgeIcon = Icons.lock;
      badgeText = 'Inscripciones cerradas';
    } else if (fechaDetalle!.estaLleno) {
      badgeColor = DesignTokens.accentColor;
      badgeIcon = Icons.group;
      badgeText = 'Fecha completa';
    } else {
      badgeColor = DesignTokens.successColor;
      badgeIcon = Icons.sports_soccer;
      badgeText = 'Inscripciones abiertas';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(badgeIcon, color: badgeColor, size: DesignTokens.iconSizeM),
          const SizedBox(width: DesignTokens.spacingS),
          Text(
            badgeText,
            style: textTheme.titleSmall?.copyWith(
              color: badgeColor,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool destacado = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeM,
          color: destacado ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: destacado
                      ? DesignTokens.fontWeightBold
                      : DesignTokens.fontWeightMedium,
                  color: destacado ? colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(
          color: fechaDetalle!.usuarioInscrito
              ? DesignTokens.successColor.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: fechaDetalle!.usuarioInscrito ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: _buildActionContent(context),
      ),
    );
  }

  Widget _buildActionContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // CA-005: Inscripciones cerradas
    if (!fechaDetalle!.inscripcionesAbiertas) {
      return Column(
        children: [
          Icon(
            Icons.lock,
            size: 48,
            color: colorScheme.error,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Inscripciones cerradas',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            fechaDetalle!.mensajeEstado ?? 'Esta fecha ya no acepta nuevas inscripciones.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // CA-004: Ya inscrito
    if (fechaDetalle!.usuarioInscrito) {
      return Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: DesignTokens.successColor,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Ya estas anotado',
            style: textTheme.titleMedium?.copyWith(
              color: DesignTokens.successColor,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Recuerda pagar ${fechaDetalle!.fecha.costoFormato} antes de la pichanga.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isProcesando
                  ? null
                  : () => _confirmarCancelacion(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
                padding: const EdgeInsets.all(DesignTokens.spacingM),
              ),
              icon: isProcesando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close),
              label: const Text('Cancelar inscripcion'),
            ),
          ),
        ],
      );
    }

    // CA-002: Puede inscribirse
    if (fechaDetalle!.puedeInscribirse) {
      return Column(
        children: [
          Icon(
            Icons.sports_soccer,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Anotate a esta pichanga',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Quedan ${fechaDetalle!.lugaresDisponibles} lugares disponibles.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isProcesando
                  ? null
                  : () => _confirmarInscripcion(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
              ),
              icon: isProcesando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sports_soccer),
              label: const Text('Anotarme'),
            ),
          ),
        ],
      );
    }

    // Fecha llena
    return Column(
      children: [
        Icon(
          Icons.group,
          size: 48,
          color: DesignTokens.accentColor,
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          'Fecha completa',
          style: textTheme.titleMedium?.copyWith(
            color: DesignTokens.accentColor,
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Text(
          'Todos los lugares han sido ocupados.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _confirmarInscripcion(BuildContext context) {
    final fecha = fechaDetalle!.fecha;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.sports_soccer,
          color: Theme.of(context).colorScheme.primary,
          size: 48,
        ),
        title: const Text('Confirmar inscripcion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Te anotaras para la pichanga:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _DialogInfoRow(icon: Icons.calendar_today, text: '${fecha.fechaFormato} - ${fecha.horaFormato}'),
            _DialogInfoRow(icon: Icons.location_on, text: fecha.lugar),
            _DialogInfoRow(
              icon: Icons.attach_money,
              text: 'Debes pagar: ${fecha.costoFormato}',
              destacado: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<InscripcionBloc>().add(
                InscribirseEvent(fechaId: fechaId),
              );
            },
            child: const Text('Anotarme'),
          ),
        ],
      ),
    );
  }

  /// E003-HU-007: Dialogo de confirmacion para cancelar inscripcion (Desktop)
  /// CA-001: Visible solo si usuario esta inscrito
  /// CA-002: Mensaje de confirmacion
  /// CA-005: Si fecha cerrada, mostrar mensaje
  void _confirmarCancelacion(BuildContext context) {
    CancelarInscripcionDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de cancelar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            errorMessage ?? 'Error al cargar detalle de la fecha',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          FilledButton.icon(
            onPressed: () {
              context.read<InscripcionBloc>().add(
                CargarFechaDetalleEvent(fechaId: fechaId),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// WIDGETS AUXILIARES
// ============================================

/// Fila de info para dialogos
class _DialogInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool destacado;

  const _DialogInfoRow({
    required this.icon,
    required this.text,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      child: Row(
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeS,
            color: destacado ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: destacado
                    ? DesignTokens.fontWeightBold
                    : DesignTokens.fontWeightRegular,
                color: destacado ? colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

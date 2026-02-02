import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/solicitud_pendiente_model.dart';
import '../bloc/solicitudes/solicitudes.dart';
import '../widgets/widgets.dart';

/// Pagina de solicitudes pendientes de aprobacion
/// E001-HU-006: Gestionar Solicitudes de Registro
///
/// Criterios de Aceptacion:
/// - CA-001: Solo admins ven la opcion (validado en sidebar)
/// - CA-002: Badge con contador de pendientes (en sidebar)
/// - CA-003: Lista con nombre, email, fecha registro, dias pendiente
/// - CA-004: Ordenar por antiguedad (mas antiguas primero)
/// - CA-005: Aprobar con selector de rol (jugador/admin/arbitro/delegado)
/// - CA-006: Rechazar con motivo opcional
/// - CA-007: Estado vacio con mensaje e icono
/// - CA-008: Dialogos de confirmacion
/// - CA-009: SnackBar de feedback
///
/// Estilo: CRM Moderno con layout de 3 columnas en desktop
/// - Sidebar (via DashboardShell)
/// - Panel de filtros lateral (320px)
/// - Tabla de datos expandida
class SolicitudesPendientesPage extends StatelessWidget {
  const SolicitudesPendientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SolicitudesBloc, SolicitudesState>(
      listener: _handleStateChanges,
      builder: (context, state) {
        // Obtener datos del estado
        final solicitudes = _obtenerSolicitudes(state);
        final total = _obtenerTotal(state);
        final isLoading = state is SolicitudesLoading;
        final errorState = state is SolicitudesError ? state : null;
        final hasError = errorState != null;
        final errorMessage = errorState?.message;
        final procesandoState =
            state is SolicitudesProcesando ? state : null;
        final procesandoId = procesandoState?.usuarioIdProcesando;

        // Calcular metricas
        final metricas = _calcularMetricas(solicitudes);

        return ResponsiveLayout(
          mobileBody: _MobileView(
            solicitudes: solicitudes,
            total: total,
            isLoading: isLoading,
            hasError: hasError,
            errorMessage: errorMessage,
            procesandoId: procesandoId,
            onRefresh: () => _onRefresh(context),
          ),
          desktopBody: _DesktopView(
            solicitudes: solicitudes,
            total: total,
            isLoading: isLoading,
            hasError: hasError,
            errorMessage: errorMessage,
            procesandoId: procesandoId,
            metricas: metricas,
            onRefresh: () => _onRefresh(context),
          ),
        );
      },
    );
  }

  List<SolicitudPendienteModel> _obtenerSolicitudes(SolicitudesState state) {
    if (state is SolicitudesLoaded) return state.solicitudes;
    if (state is SolicitudesProcesando) return state.solicitudes;
    if (state is SolicitudesError && state.solicitudesPrevias != null) {
      return state.solicitudesPrevias!;
    }
    return [];
  }

  int _obtenerTotal(SolicitudesState state) {
    if (state is SolicitudesLoaded) return state.total;
    if (state is SolicitudesProcesando) return state.solicitudes.length;
    if (state is SolicitudesError && state.solicitudesPrevias != null) {
      return state.solicitudesPrevias!.length;
    }
    return 0;
  }

  Map<String, dynamic> _calcularMetricas(
      List<SolicitudPendienteModel> solicitudes) {
    final totalSolicitudes = solicitudes.length;

    // Calcular dias pendiente maximo
    int maxDiasPendiente = 0;
    double sumaDias = 0;

    for (final s in solicitudes) {
      if (s.diasPendiente > maxDiasPendiente) {
        maxDiasPendiente = s.diasPendiente;
      }
      sumaDias += s.diasPendiente;
    }

    final promedioDias =
        totalSolicitudes > 0 ? (sumaDias / totalSolicitudes).round() : 0;

    // Contar por urgencia
    int normales = 0;
    int atencion = 0;
    int urgentes = 0;

    for (final s in solicitudes) {
      if (s.diasPendiente > 7) {
        urgentes++;
      } else if (s.diasPendiente >= 3) {
        atencion++;
      } else {
        normales++;
      }
    }

    return {
      'total': totalSolicitudes,
      'maxDias': maxDiasPendiente,
      'promedioDias': promedioDias,
      'normales': normales,
      'atencion': atencion,
      'urgentes': urgentes,
    };
  }

  void _onRefresh(BuildContext context) {
    context.read<SolicitudesBloc>().add(const CargarSolicitudesEvent());
  }

  void _handleStateChanges(BuildContext context, SolicitudesState state) {
    // CA-009: SnackBar de feedback
    if (state is SolicitudesLoaded && state.mensajeExito != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(child: Text(state.mensajeExito!)),
            ],
          ),
          backgroundColor: DesignTokens.successColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(DesignTokens.spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
        ),
      );
      // Limpiar mensaje despues de mostrar
      context
          .read<SolicitudesBloc>()
          .add(const LimpiarMensajeSolicitudesEvent());
    }

    if (state is SolicitudesError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: DesignTokens.errorColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(DesignTokens.spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
        ),
      );
    }
  }
}

// ============================================
// VISTA MOBILE - App Style con Cards
// ============================================

class _MobileView extends StatelessWidget {
  final List<SolicitudPendienteModel> solicitudes;
  final int total;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final String? procesandoId;
  final VoidCallback onRefresh;

  const _MobileView({
    required this.solicitudes,
    required this.total,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.procesandoId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Solicitudes Pendientes'),
        centerTitle: true,
        actions: [
          // Contador de pendientes
          if (solicitudes.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: DesignTokens.spacingS),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Text(
                '${solicitudes.length}',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Estado de carga inicial
    if (isLoading && solicitudes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error sin datos previos
    if (hasError && solicitudes.isEmpty) {
      return EmptyStateWidget.error(
        title: 'Error al cargar solicitudes',
        description: errorMessage ?? 'Ocurrio un error inesperado',
        actionLabel: 'Reintentar',
        onAction: onRefresh,
      );
    }

    // CA-007: Estado vacio con mensaje e icono
    if (solicitudes.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        title: 'No hay solicitudes pendientes',
        description: 'Todas las solicitudes de registro han sido procesadas',
      );
    }

    // Lista con datos
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final solicitud = solicitudes[index];
              final isProcessing = procesandoId == solicitud.id;

              return SolicitudCard(
                solicitud: solicitud,
                isProcessing: isProcessing,
                onAprobar: () => _mostrarDialogAprobar(context, solicitud),
                onRechazar: () => _mostrarDialogRechazar(context, solicitud),
              );
            },
          ),
          if (isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _mostrarDialogAprobar(
    BuildContext context,
    SolicitudPendienteModel solicitud,
  ) async {
    final rol = await AprobarDialog.show(
      context: context,
      nombreUsuario: solicitud.nombreCompleto,
    );

    if (rol != null && context.mounted) {
      context.read<SolicitudesBloc>().add(
            AprobarSolicitudEvent(
              usuarioId: solicitud.id,
              nombreUsuario: solicitud.nombreCompleto,
              rol: rol,
            ),
          );
    }
  }

  void _mostrarDialogRechazar(
    BuildContext context,
    SolicitudPendienteModel solicitud,
  ) async {
    await RechazarDialog.show(
      context: context,
      nombreUsuario: solicitud.nombreCompleto,
      onConfirmar: (motivo) {
        context.read<SolicitudesBloc>().add(
              RechazarSolicitudEvent(
                usuarioId: solicitud.id,
                nombreUsuario: solicitud.nombreCompleto,
                motivo: motivo,
              ),
            );
      },
    );
  }
}

// ============================================
// VISTA DESKTOP - CRM Style con 3 Columnas
// ============================================

class _DesktopView extends StatelessWidget {
  final List<SolicitudPendienteModel> solicitudes;
  final int total;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final String? procesandoId;
  final Map<String, dynamic> metricas;
  final VoidCallback onRefresh;

  const _DesktopView({
    required this.solicitudes,
    required this.total,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.procesandoId,
    required this.metricas,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/admin/solicitudes',
      title: 'Solicitudes Pendientes',
      breadcrumbs: const ['Inicio', 'Administracion', 'Solicitudes'],
      actions: [
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar lista',
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel de filtros lateral (320px fijo)
          SizedBox(
            width: 320,
            child: _FilterPanel(
              metricas: metricas,
              onRefresh: onRefresh,
            ),
          ),

          // Separador vertical
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),

          // Tabla de datos (expandida)
          Expanded(
            child: _DataTablePanel(
              solicitudes: solicitudes,
              total: total,
              isLoading: isLoading,
              hasError: hasError,
              errorMessage: errorMessage,
              procesandoId: procesandoId,
              onRefresh: onRefresh,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// PANEL DE FILTROS (320px)
// ============================================

class _FilterPanel extends StatelessWidget {
  final Map<String, dynamic> metricas;
  final VoidCallback onRefresh;

  const _FilterPanel({
    required this.metricas,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del panel
          Text(
            'Solicitudes de Registro',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            'Gestiona las solicitudes pendientes de aprobacion',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Card de metricas principales
          AppCard(
            variant: AppCardVariant.outlined,
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Text(
                      'RESUMEN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingM),

                // Metricas en grid 2x2
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Total Pendientes',
                        value: metricas['total'] ?? 0,
                        icon: Icons.pending_actions,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: _MetricTile(
                        label: 'Mas Antigua',
                        value: metricas['maxDias'] ?? 0,
                        suffix: 'd',
                        icon: Icons.schedule,
                        color: DesignTokens.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Promedio Dias',
                        value: metricas['promedioDias'] ?? 0,
                        suffix: 'd',
                        icon: Icons.timelapse,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: _MetricTile(
                        label: 'Urgentes',
                        value: metricas['urgentes'] ?? 0,
                        icon: Icons.warning_amber,
                        color: DesignTokens.errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Informacion sobre el proceso
          AppCard(
            variant: AppCardVariant.outlined,
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Text(
                      'PROCESO DE APROBACION',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Al aprobar una solicitud, deberas asignar un rol al usuario. Los roles disponibles son:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingM),
                _RolInfoItem(
                  icon: Icons.person,
                  label: 'Jugador',
                  description: 'Acceso basico',
                  color: colorScheme.tertiary,
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                _RolInfoItem(
                  icon: Icons.sports,
                  label: 'Entrenador',
                  description: 'Gestiona equipos',
                  color: DesignTokens.secondaryColor,
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                _RolInfoItem(
                  icon: Icons.gavel,
                  label: 'Arbitro',
                  description: 'Registra partidos',
                  color: DesignTokens.accentColor,
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                _RolInfoItem(
                  icon: Icons.admin_panel_settings,
                  label: 'Admin',
                  description: 'Acceso completo',
                  color: DesignTokens.primaryColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Leyenda de urgencia
          Text(
            'INDICADORES DE URGENCIA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightSemiBold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          _UrgencyLegend(),

          const SizedBox(height: DesignTokens.spacingL),

          // Boton de actualizar
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar Lista'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// PANEL DE DATOS (Tabla)
// ============================================

class _DataTablePanel extends StatelessWidget {
  final List<SolicitudPendienteModel> solicitudes;
  final int total;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final String? procesandoId;
  final VoidCallback onRefresh;

  const _DataTablePanel({
    required this.solicitudes,
    required this.total,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.procesandoId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la tabla
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listado de Solicitudes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXxs),
                    Text(
                      'Solicitudes ordenadas por antiguedad (mas antiguas primero)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Contador de registros
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pending_actions,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: DesignTokens.spacingXs),
                    Text(
                      '${solicitudes.length} solicitud${solicitudes.length != 1 ? 'es' : ''} pendiente${solicitudes.length != 1 ? 's' : ''}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Contenido de la tabla
        Expanded(
          child: _buildTableContent(context),
        ),
      ],
    );
  }

  Widget _buildTableContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Estado de carga inicial
    if (isLoading && solicitudes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error sin datos previos
    if (hasError && solicitudes.isEmpty) {
      return Center(
        child: EmptyStateWidget.error(
          title: 'Error al cargar solicitudes',
          description: errorMessage ?? 'Ocurrio un error inesperado',
          actionLabel: 'Reintentar',
          onAction: onRefresh,
        ),
      );
    }

    // CA-007: Estado vacio
    if (solicitudes.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          icon: Icons.inbox_outlined,
          title: 'No hay solicitudes pendientes',
          description: 'Todas las solicitudes de registro han sido procesadas',
        ),
      );
    }

    // Tabla con datos
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: AppCard(
            variant: AppCardVariant.outlined,
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width -
                        320 -
                        280 -
                        DesignTokens.spacingL * 2,
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    ),
                    columns: const [
                      DataColumn(label: Text('Solicitante')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Fecha Registro')),
                      DataColumn(label: Text('Dias Pendiente')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: solicitudes.map((solicitud) {
                      final isProcessing = procesandoId == solicitud.id;

                      return DataRow(
                        cells: [
                          // Columna: Solicitante (Avatar + Nombre)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildAvatar(solicitud, colorScheme),
                                const SizedBox(width: DesignTokens.spacingM),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 180),
                                  child: Text(
                                    solicitud.nombreCompleto,
                                    style: const TextStyle(
                                      fontWeight: DesignTokens.fontWeightMedium,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Columna: Email
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                solicitud.email,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          // Columna: Fecha Registro
                          DataCell(
                            Text(
                              solicitud.fechaRegistroCorta,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),

                          // Columna: Dias Pendiente (Badge de urgencia)
                          DataCell(
                            _buildUrgencyBadge(solicitud, colorScheme),
                          ),

                          // Columna: Acciones
                          DataCell(
                            _buildAcciones(
                              context,
                              solicitud,
                              isProcessing,
                              colorScheme,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildAvatar(
      SolicitudPendienteModel solicitud, ColorScheme colorScheme) {
    final inicial = solicitud.nombreCompleto.isNotEmpty
        ? solicitud.nombreCompleto[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 18,
      backgroundColor: colorScheme.primary,
      child: Text(
        inicial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: DesignTokens.fontWeightBold,
          fontSize: DesignTokens.fontSizeS,
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(
      SolicitudPendienteModel solicitud, ColorScheme colorScheme) {
    StatusBadgeType type;
    String label;

    if (solicitud.diasPendiente > 7) {
      // Urgente (rojo): > 7 dias
      type = StatusBadgeType.derrota;
      label = '${solicitud.diasPendiente}d - Urgente';
    } else if (solicitud.diasPendiente >= 3) {
      // Atencion (amarillo): 3-7 dias
      type = StatusBadgeType.enCurso;
      label = '${solicitud.diasPendiente}d - Atencion';
    } else {
      // Normal (azul): < 3 dias
      type = StatusBadgeType.programado;
      label = solicitud.diasPendienteTexto;
    }

    return StatusBadge(
      label: label,
      type: type,
      size: StatusBadgeSize.small,
    );
  }

  Widget _buildAcciones(
    BuildContext context,
    SolicitudPendienteModel solicitud,
    bool isProcessing,
    ColorScheme colorScheme,
  ) {
    if (isProcessing) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Boton Aprobar (verde)
        Tooltip(
          message: 'Aprobar solicitud',
          child: IconButton(
            onPressed: () => _mostrarDialogAprobar(context, solicitud),
            icon: const Icon(Icons.check_circle_outline),
            color: DesignTokens.successColor,
            iconSize: DesignTokens.iconSizeS + 4,
          ),
        ),
        // Boton Rechazar (rojo)
        Tooltip(
          message: 'Rechazar solicitud',
          child: IconButton(
            onPressed: () => _mostrarDialogRechazar(context, solicitud),
            icon: const Icon(Icons.cancel_outlined),
            color: DesignTokens.errorColor,
            iconSize: DesignTokens.iconSizeS + 4,
          ),
        ),
      ],
    );
  }

  /// CA-008: Dialogo de confirmacion para aprobar
  void _mostrarDialogAprobar(
    BuildContext context,
    SolicitudPendienteModel solicitud,
  ) async {
    final rol = await AprobarDialog.show(
      context: context,
      nombreUsuario: solicitud.nombreCompleto,
    );

    if (rol != null && context.mounted) {
      context.read<SolicitudesBloc>().add(
            AprobarSolicitudEvent(
              usuarioId: solicitud.id,
              nombreUsuario: solicitud.nombreCompleto,
              rol: rol,
            ),
          );
    }
  }

  /// CA-008: Dialogo de confirmacion para rechazar
  void _mostrarDialogRechazar(
    BuildContext context,
    SolicitudPendienteModel solicitud,
  ) async {
    await RechazarDialog.show(
      context: context,
      nombreUsuario: solicitud.nombreCompleto,
      onConfirmar: (motivo) {
        context.read<SolicitudesBloc>().add(
              RechazarSolicitudEvent(
                usuarioId: solicitud.id,
                nombreUsuario: solicitud.nombreCompleto,
                motivo: motivo,
              ),
            );
      },
    );
  }
}

// ============================================
// WIDGETS AUXILIARES
// ============================================

/// Tile de metrica para el panel de filtros
class _MetricTile extends StatelessWidget {
  final String label;
  final int value;
  final String? suffix;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    this.suffix,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: DesignTokens.iconSizeS, color: color),
              const Spacer(),
              Text(
                suffix != null ? '$value$suffix' : value.toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingXxs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Item de informacion de rol
class _RolInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const _RolInfoItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Icon(icon, size: DesignTokens.iconSizeS, color: color),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingXs),
              Text(
                '- $description',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Leyenda de urgencia
class _UrgencyLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _UrgencyLegendItem(
          color: DesignTokens.primaryColor,
          label: 'Normal',
          description: 'Menos de 3 dias',
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        _UrgencyLegendItem(
          color: DesignTokens.accentColor,
          label: 'Atencion',
          description: '3 a 7 dias',
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        _UrgencyLegendItem(
          color: DesignTokens.errorColor,
          label: 'Urgente',
          description: 'Mas de 7 dias',
        ),
      ],
    );
  }
}

class _UrgencyLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String description;

  const _UrgencyLegendItem({
    required this.color,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        const SizedBox(width: DesignTokens.spacingXs),
        Text(
          '($description)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: DesignTokens.fontSizeXs,
          ),
        ),
      ],
    );
  }
}

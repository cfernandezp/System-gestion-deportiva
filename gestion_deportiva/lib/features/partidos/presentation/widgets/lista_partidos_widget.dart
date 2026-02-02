import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../../fechas/data/models/fecha_detalle_model.dart';
import '../../data/models/listar_partidos_response_model.dart';
import '../bloc/lista_partidos/lista_partidos.dart';
import '../bloc/partido/partido.dart';
import 'iniciar_partido_dialog.dart';

/// Widget que muestra la lista de partidos de una fecha
/// Incluye:
/// - Header "Partidos (N)" con boton "+ Nuevo" si puedeCrearPartido
/// - Lista de partidos con indicador de estado, equipos, marcador, hora
/// - Estado vacio si no hay partidos
/// - Botones de accion segun estado del partido
class ListaPartidosWidget extends StatelessWidget {
  /// Detalle de la fecha actual
  final FechaDetalleModel fechaDetalle;

  /// Callback cuando se crea un nuevo partido exitosamente
  final VoidCallback? onPartidoCreado;

  /// Callback cuando se selecciona un partido
  final void Function(PartidoListaModel partido)? onPartidoSeleccionado;

  /// Indica si el usuario es admin
  final bool esAdmin;

  const ListaPartidosWidget({
    super.key,
    required this.fechaDetalle,
    this.onPartidoCreado,
    this.onPartidoSeleccionado,
    this.esAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ListaPartidosBloc>()
        ..add(CargarPartidosEvent(fechaId: fechaDetalle.fecha.fechaId)),
      child: _ListaPartidosContent(
        fechaDetalle: fechaDetalle,
        onPartidoCreado: onPartidoCreado,
        onPartidoSeleccionado: onPartidoSeleccionado,
        esAdmin: esAdmin,
      ),
    );
  }
}

class _ListaPartidosContent extends StatelessWidget {
  final FechaDetalleModel fechaDetalle;
  final VoidCallback? onPartidoCreado;
  final void Function(PartidoListaModel partido)? onPartidoSeleccionado;
  final bool esAdmin;

  const _ListaPartidosContent({
    required this.fechaDetalle,
    this.onPartidoCreado,
    this.onPartidoSeleccionado,
    required this.esAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<ListaPartidosBloc, ListaPartidosState>(
      builder: (context, state) {
        final isLoading = state is ListaPartidosLoading;
        final errorState =
            state is ListaPartidosError ? state : null;
        final loadedState =
            state is ListaPartidosLoaded ? state : null;
        final partidos = loadedState?.partidos ?? <PartidoListaModel>[];
        final total = loadedState?.total ?? 0;
        final puedeCrearPartido = loadedState?.puedeCrearPartido ?? false;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(
                context,
                colorScheme,
                textTheme,
                total,
                puedeCrearPartido && esAdmin,
              ),

              const Divider(height: 1),

              // Contenido
              if (isLoading)
                _buildLoading(colorScheme)
              else if (errorState != null)
                _buildError(context, errorState, colorScheme)
              else if (partidos.isEmpty)
                _buildEmpty(colorScheme, textTheme)
              else
                _buildListaPartidos(context, partidos, colorScheme, textTheme),
            ],
          ),
        );
      },
    );
  }

  /// Header con titulo y boton de nuevo partido
  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    int total,
    bool mostrarBotonNuevo,
  ) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Row(
        children: [
          Icon(
            Icons.sports_soccer,
            color: colorScheme.primary,
            size: DesignTokens.iconSizeM,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              'Partidos ($total)',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
          ),
          if (mostrarBotonNuevo)
            FilledButton.icon(
              onPressed: () => _mostrarDialogoNuevoPartido(context),
              icon: const Icon(Icons.add, size: DesignTokens.iconSizeS),
              label: const Text('Nuevo'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Estado de carga
  Widget _buildLoading(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingXl),
      child: Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      ),
    );
  }

  /// Estado de error
  Widget _buildError(
    BuildContext context,
    ListaPartidosError errorState,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: DesignTokens.errorColor,
            size: DesignTokens.iconSizeXl,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            errorState.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          TextButton.icon(
            onPressed: () => context
                .read<ListaPartidosBloc>()
                .add(CargarPartidosEvent(fechaId: fechaDetalle.fecha.fechaId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Estado vacio
  Widget _buildEmpty(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        children: [
          Icon(
            Icons.sports_soccer_outlined,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: DesignTokens.iconSizeXl,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'No hay partidos registrados',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            'Los partidos apareceran aqui cuando se inicien',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Lista de partidos en formato tabla horizontal
  Widget _buildListaPartidos(
    BuildContext context,
    List<PartidoListaModel> partidos,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        // Header de tabla
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  'Estado',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Enfrentamiento',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'Score',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  'Hora',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        // Filas de partidos
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: partidos.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          itemBuilder: (context, index) {
            final partido = partidos[index];
            return _PartidoRow(
              partido: partido,
              onTap: onPartidoSeleccionado != null
                  ? () => onPartidoSeleccionado!(partido)
                  : null,
            );
          },
        ),
      ],
    );
  }

  /// Muestra el dialogo para crear nuevo partido
  void _mostrarDialogoNuevoPartido(BuildContext context) {
    final numEquipos = fechaDetalle.fecha.numEquipos;
    final equiposDisponibles = <ColorEquipo>[
      ColorEquipo.naranja,
      ColorEquipo.verde,
      if (numEquipos >= 3) ColorEquipo.azul,
    ];

    // Duracion segun numero de equipos: 2 equipos = 20 min, 3 equipos = 10 min
    final duracionMinutos = numEquipos == 2 ? 20 : 10;

    // Obtener PartidoBloc del contexto padre si existe
    final partidoBloc = context.read<PartidoBloc>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: partidoBloc,
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
              maxHeight: 650,
            ),
            child: IniciarPartidoDialog(
              fechaDetalle: fechaDetalle,
              equiposDisponibles: equiposDisponibles,
              duracionMinutos: duracionMinutos,
              onSuccess: () {
                // Refrescar lista de partidos
                context.read<ListaPartidosBloc>().add(
                      RefrescarPartidosEvent(
                          fechaId: fechaDetalle.fecha.fechaId),
                    );
                onPartidoCreado?.call();
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila individual de partido (formato tabla horizontal)
class _PartidoRow extends StatelessWidget {
  final PartidoListaModel partido;
  final VoidCallback? onTap;

  const _PartidoRow({
    required this.partido,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: _getBackgroundColor(colorScheme),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          child: Row(
            children: [
              // Estado
              SizedBox(
                width: 80,
                child: _buildEstadoBadge(colorScheme, textTheme),
              ),

              // Enfrentamiento: Local vs Visitante
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Equipo Local
                    _buildEquipoBadge(partido.equipoLocal),

                    // VS
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingS,
                      ),
                      child: Text(
                        'vs',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                    // Equipo Visitante
                    _buildEquipoBadge(partido.equipoVisitante),
                  ],
                ),
              ),

              // Score
              SizedBox(
                width: 60,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Text(
                    partido.marcador,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Hora
              SizedBox(
                width: 50,
                child: Text(
                  partido.horaInicio ?? '--:--',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Badge de estado compacto
  Widget _buildEstadoBadge(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingXs,
        vertical: DesignTokens.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: _getEstadoColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getEstadoColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _getEstadoTexto(),
            style: textTheme.labelSmall?.copyWith(
              color: _getEstadoColor(),
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge de equipo con color
  Widget _buildEquipoBadge(ColorEquipo equipo) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: equipo.color,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        border: Border.all(color: equipo.borderColor, width: 0.5),
      ),
      child: Text(
        equipo.displayName.toUpperCase(),
        style: TextStyle(
          color: equipo.textColor,
          fontWeight: DesignTokens.fontWeightBold,
          fontSize: 10,
        ),
      ),
    );
  }

  /// Color de fondo segun estado
  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (partido.estaEnCurso) {
      return DesignTokens.successColor.withValues(alpha: 0.05);
    }
    if (partido.estaPausado) {
      return DesignTokens.accentColor.withValues(alpha: 0.05);
    }
    return Colors.transparent;
  }

  /// Color del indicador de estado
  Color _getEstadoColor() {
    switch (partido.estado) {
      case 'en_curso':
        return DesignTokens.successColor;
      case 'pausado':
        return DesignTokens.accentColor;
      case 'finalizado':
        return DesignTokens.secondaryColor;
      case 'pendiente':
        return Colors.grey;
      case 'cancelado':
        return DesignTokens.errorColor;
      default:
        return Colors.grey;
    }
  }

  /// Texto del estado
  String _getEstadoTexto() {
    switch (partido.estado) {
      case 'en_curso':
        return 'En curso';
      case 'pausado':
        return 'Pausado';
      case 'finalizado':
        return 'Finalizado';
      case 'pendiente':
        return 'Pendiente';
      case 'cancelado':
        return 'Cancelado';
      default:
        return partido.estado;
    }
  }
}

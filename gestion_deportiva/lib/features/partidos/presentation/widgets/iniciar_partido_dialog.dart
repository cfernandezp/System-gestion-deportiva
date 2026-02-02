import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../../fechas/data/models/fecha_detalle_model.dart';
import '../bloc/partido/partido.dart';

/// Dialog para iniciar un partido
/// E004-HU-001: Iniciar Partido
/// CA-001: Seleccionar equipos con colores distintivos
/// CA-002: Mostrar duracion automatica (10 o 20 min)
/// RN-006: Validar equipos diferentes
class IniciarPartidoDialog extends StatefulWidget {
  /// Detalle de la fecha actual
  final FechaDetalleModel fechaDetalle;

  /// Equipos disponibles con jugadores asignados
  final List<ColorEquipo> equiposDisponibles;

  /// Duracion del partido en minutos (calculada por backend)
  final int duracionMinutos;

  /// Callback cuando se inicia exitosamente
  final VoidCallback? onSuccess;

  const IniciarPartidoDialog({
    super.key,
    required this.fechaDetalle,
    required this.equiposDisponibles,
    required this.duracionMinutos,
    this.onSuccess,
  });

  /// Muestra el dialog de iniciar partido
  /// Mobile: BottomSheet
  /// Desktop: Dialog centrado
  static Future<void> show(
    BuildContext context, {
    required FechaDetalleModel fechaDetalle,
    required List<ColorEquipo> equiposDisponibles,
    required int duracionMinutos,
    VoidCallback? onSuccess,
  }) async {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < DesignTokens.breakpointMobile;

    // Obtener el bloc existente del contexto padre
    final partidoBloc = context.read<PartidoBloc>();

    if (isMobile) {
      // Mobile: BottomSheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (dialogContext) => BlocProvider.value(
          value: partidoBloc,
          child: IniciarPartidoDialog(
            fechaDetalle: fechaDetalle,
            equiposDisponibles: equiposDisponibles,
            duracionMinutos: duracionMinutos,
            onSuccess: onSuccess,
          ),
        ),
      );
    } else {
      // Desktop: Dialog centrado
      await showDialog(
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
                onSuccess: onSuccess,
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  State<IniciarPartidoDialog> createState() => _IniciarPartidoDialogState();
}

class _IniciarPartidoDialogState extends State<IniciarPartidoDialog> {
  ColorEquipo? _equipoLocal;
  ColorEquipo? _equipoVisitante;

  /// RN-006: Validar equipos diferentes
  bool get _equiposValidos =>
      _equipoLocal != null &&
      _equipoVisitante != null &&
      _equipoLocal != _equipoVisitante;

  /// Mensaje de error si equipos son iguales
  String? get _errorEquipos {
    if (_equipoLocal != null &&
        _equipoVisitante != null &&
        _equipoLocal == _equipoVisitante) {
      return 'Los equipos deben ser diferentes';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < DesignTokens.breakpointMobile;

    return BlocConsumer<PartidoBloc, PartidoState>(
      listener: (context, state) {
        if (state is PartidoEnCurso) {
          // Cerrar el dialog
          Navigator.of(context).pop();

          // Mostrar mensaje de exito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.sports_soccer, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      state.message.isNotEmpty
                          ? state.message
                          : 'Partido iniciado: ${state.enfrentamientoDisplay}',
                    ),
                  ),
                ],
              ),
              backgroundColor: DesignTokens.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Callback de exito
          widget.onSuccess?.call();
        }

        if (state is PartidoError) {
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
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is PartidoProcesando;

        if (isMobile) {
          return _buildBottomSheetContent(context, colorScheme, isLoading);
        } else {
          return _buildDialogContent(context, colorScheme, isLoading);
        }
      },
    );
  }

  /// Contenido para BottomSheet (Mobile)
  Widget _buildBottomSheetContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeL,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    'Iniciar Partido',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Contenido scrolleable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              child: _buildContent(context, colorScheme),
            ),
          ),

          // Botones de accion
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: isLoading || !_equiposValidos
                          ? null
                          : () => _iniciarPartido(context),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: const Text('Iniciar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido para Dialog (Desktop)
  Widget _buildDialogContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingS),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Icon(
                    Icons.sports_soccer,
                    color: colorScheme.onPrimaryContainer,
                    size: DesignTokens.iconSizeL,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Iniciar Partido',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: DesignTokens.fontWeightBold,
                            ),
                      ),
                      Text(
                        'Selecciona los equipos que jugaran',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Contenido scrolleable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacingL),
              child: _buildContent(context, colorScheme),
            ),
          ),

          const Divider(height: 1),

          // Botones de accion
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                FilledButton.icon(
                  onPressed: isLoading || !_equiposValidos
                      ? null
                      : () => _iniciarPartido(context),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('Iniciar Partido'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido compartido del selector de equipos
  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CA-002: Mostrar duracion automatica
        Container(
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
              Icon(
                Icons.timer,
                color: colorScheme.primary,
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duracion del partido',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${widget.duracionMinutos} minutos',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.auto_mode,
                color: colorScheme.primary.withValues(alpha: 0.5),
                size: DesignTokens.iconSizeS,
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // CA-001: Selector de equipo local
        Text(
          'Equipo Local',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        _buildEquipoSelector(
          context,
          equipoSeleccionado: _equipoLocal,
          equipoOcupado: _equipoVisitante,
          onSeleccionar: (equipo) {
            setState(() => _equipoLocal = equipo);
          },
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // VS central
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingL,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            child: Text(
              'VS',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // CA-001: Selector de equipo visitante
        Text(
          'Equipo Visitante',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        _buildEquipoSelector(
          context,
          equipoSeleccionado: _equipoVisitante,
          equipoOcupado: _equipoLocal,
          onSeleccionar: (equipo) {
            setState(() => _equipoVisitante = equipo);
          },
        ),

        // RN-006: Mensaje de error si equipos son iguales
        if (_errorEquipos != null) ...[
          const SizedBox(height: DesignTokens.spacingM),
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: DesignTokens.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: DesignTokens.errorColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: DesignTokens.errorColor,
                  size: DesignTokens.iconSizeM,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Text(
                    _errorEquipos!,
                    style: TextStyle(
                      color: DesignTokens.errorColor,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Preview del enfrentamiento
        if (_equiposValidos) ...[
          const SizedBox(height: DesignTokens.spacingL),
          _buildPreviewEnfrentamiento(context, colorScheme),
        ],
      ],
    );
  }

  /// Selector de equipo con botones de colores
  Widget _buildEquipoSelector(
    BuildContext context, {
    required ColorEquipo? equipoSeleccionado,
    required ColorEquipo? equipoOcupado,
    required ValueChanged<ColorEquipo> onSeleccionar,
  }) {
    return Wrap(
      spacing: DesignTokens.spacingS,
      runSpacing: DesignTokens.spacingS,
      children: widget.equiposDisponibles.map((equipo) {
        final isSeleccionado = equipo == equipoSeleccionado;
        final isOcupado = equipo == equipoOcupado;

        return _EquipoButton(
          equipo: equipo,
          isSeleccionado: isSeleccionado,
          isDisabled: isOcupado,
          onTap: isOcupado ? null : () => onSeleccionar(equipo),
        );
      }).toList(),
    );
  }

  /// Preview del enfrentamiento seleccionado
  Widget _buildPreviewEnfrentamiento(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Enfrentamiento',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Equipo local
              _EquipoBadge(equipo: _equipoLocal!),
              const SizedBox(width: DesignTokens.spacingM),
              Text(
                'vs',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingM),
              // Equipo visitante
              _EquipoBadge(equipo: _equipoVisitante!),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            '${widget.duracionMinutos} minutos',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.secondary,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Inicia el partido
  void _iniciarPartido(BuildContext context) {
    if (!_equiposValidos) return;

    context.read<PartidoBloc>().add(
          IniciarPartidoEvent(
            fechaId: widget.fechaDetalle.fecha.fechaId,
            equipoLocal: _equipoLocal!.toBackend(),
            equipoVisitante: _equipoVisitante!.toBackend(),
          ),
        );
  }
}

/// Boton de seleccion de equipo con color
class _EquipoButton extends StatelessWidget {
  final ColorEquipo equipo;
  final bool isSeleccionado;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _EquipoButton({
    required this.equipo,
    required this.isSeleccionado,
    required this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: DesignTokens.animFast,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: AnimatedContainer(
            duration: DesignTokens.animFast,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: isSeleccionado
                  ? equipo.color
                  : isDisabled
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                      : equipo.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: isSeleccionado
                    ? equipo.borderColor
                    : isDisabled
                        ? colorScheme.outlineVariant
                        : equipo.color.withValues(alpha: 0.5),
                width: isSeleccionado ? 2 : 1,
              ),
              boxShadow: isSeleccionado ? DesignTokens.shadowSm : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circulo de color
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: equipo.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: equipo.borderColor,
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  equipo.displayName,
                  style: TextStyle(
                    color: isSeleccionado
                        ? equipo.textColor
                        : isDisabled
                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                            : colorScheme.onSurface,
                    fontWeight: isSeleccionado
                        ? DesignTokens.fontWeightBold
                        : DesignTokens.fontWeightMedium,
                  ),
                ),
                if (isSeleccionado) ...[
                  const SizedBox(width: DesignTokens.spacingXs),
                  Icon(
                    Icons.check_circle,
                    size: DesignTokens.iconSizeS,
                    color: equipo.textColor,
                  ),
                ],
                if (isDisabled) ...[
                  const SizedBox(width: DesignTokens.spacingXs),
                  Icon(
                    Icons.block,
                    size: DesignTokens.iconSizeS,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge de equipo para preview
class _EquipoBadge extends StatelessWidget {
  final ColorEquipo equipo;

  const _EquipoBadge({required this.equipo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: equipo.color,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: equipo.borderColor, width: 2),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Text(
        equipo.displayName.toUpperCase(),
        style: TextStyle(
          color: equipo.textColor,
          fontWeight: DesignTokens.fontWeightBold,
          fontSize: DesignTokens.fontSizeS,
        ),
      ),
    );
  }
}

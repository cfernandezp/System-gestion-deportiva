import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/obtener_asignaciones_response_model.dart';
import '../bloc/asignaciones/asignaciones.dart';

/// Dialog de confirmacion para confirmar asignacion de equipos
/// E003-HU-005: Asignar Equipos
/// CA-006: Advertencia si desbalanceado
/// CA-007: Confirmar asignacion
/// RN-005: Todos los jugadores deben tener equipo
/// RN-006: Balance de equipos (advertencia si diferencia > 1)
/// RN-007: Notificacion a jugadores
class ConfirmarEquiposDialog extends StatelessWidget {
  /// ID de la fecha
  final String fechaId;

  /// Datos de asignaciones para mostrar resumen
  final ObtenerAsignacionesDataModel data;

  /// Si hay desbalance entre equipos
  final bool hayDesbalance;

  const ConfirmarEquiposDialog({
    super.key,
    required this.fechaId,
    required this.data,
    required this.hayDesbalance,
  });

  /// Muestra el dialog de confirmacion
  /// Mobile: BottomSheet
  /// Desktop: Dialog centrado
  static Future<void> show(
    BuildContext context, {
    required String fechaId,
    required ObtenerAsignacionesDataModel data,
    required bool hayDesbalance,
  }) async {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;
    final bloc = context.read<AsignacionesBloc>();

    if (isMobile) {
      // Mobile: BottomSheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => BlocProvider.value(
          value: bloc,
          child: ConfirmarEquiposDialog(
            fechaId: fechaId,
            data: data,
            hayDesbalance: hayDesbalance,
          ),
        ),
      );
    } else {
      // Desktop: Dialog centrado
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => BlocProvider.value(
          value: bloc,
          child: Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
                maxHeight: 600,
              ),
              child: ConfirmarEquiposDialog(
                fechaId: fechaId,
                data: data,
                hayDesbalance: hayDesbalance,
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return BlocConsumer<AsignacionesBloc, AsignacionesState>(
      listener: (context, state) {
        if (state is EquiposConfirmados) {
          // Cerrar dialog - el listener del page manejara el mensaje
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isLoading = state is ConfirmandoEquipos;

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
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeL,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    'Confirmar Equipos',
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
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: isLoading ? null : () => _confirmarEquipos(context),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Confirmar'),
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
                    Icons.check_circle,
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
                        'Confirmar Equipos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      Text(
                        'Los jugadores seran notificados',
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
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                FilledButton.icon(
                  onPressed: isLoading ? null : () => _confirmarEquipos(context),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Confirmar Equipos'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido compartido del resumen
  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Descripcion
        Text(
          'Vas a confirmar la asignacion de equipos. Una vez confirmados:',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: DesignTokens.spacingM),

        // Lista de consecuencias
        _buildConsequenceItem(
          context,
          icon: Icons.notifications_active,
          text: 'Todos los jugadores recibiran una notificacion con su equipo',
        ),
        _buildConsequenceItem(
          context,
          icon: Icons.group,
          text: 'Cada jugador vera la lista de sus companeros de equipo',
        ),
        _buildConsequenceItem(
          context,
          icon: Icons.edit,
          text: 'Podras modificar los equipos antes de que inicie la pichanga',
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // Resumen de equipos
        Text(
          'Resumen de equipos',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),

        const SizedBox(height: DesignTokens.spacingS),

        // Cards de equipos
        ...data.coloresDisponibles.map((color) {
          final jugadoresEquipo = data.jugadoresDelEquipo(color);
          return Container(
            margin: const EdgeInsets.only(bottom: DesignTokens.spacingS),
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: color.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: color.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.color,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Icon(
                    Icons.sports_soccer,
                    color: color.textColor,
                    size: DesignTokens.iconSizeM,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equipo ${color.displayName}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                      Text(
                        '${jugadoresEquipo.length} jugador${jugadoresEquipo.length != 1 ? 'es' : ''}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de iniciales
                if (jugadoresEquipo.isNotEmpty)
                  Wrap(
                    spacing: -8,
                    children: jugadoresEquipo.take(5).map((jugador) {
                      return Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.color,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            jugador.displayName.isNotEmpty
                                ? jugador.displayName[0].toUpperCase()
                                : '?',
                            style: textTheme.labelSmall?.copyWith(
                              color: color.textColor,
                              fontWeight: DesignTokens.fontWeightBold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                if (jugadoresEquipo.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(left: DesignTokens.spacingXs),
                    child: Text(
                      '+${jugadoresEquipo.length - 5}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),

        // CA-006: Advertencia de desbalance
        if (hayDesbalance) ...[
          const SizedBox(height: DesignTokens.spacingM),
          _buildDesbalanceWarning(context, colorScheme),
        ],
      ],
    );
  }

  /// Item de consecuencia
  Widget _buildConsequenceItem(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeS,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// RN-006: Banner de advertencia de desbalance
  Widget _buildDesbalanceWarning(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            color: DesignTokens.accentColor,
            size: DesignTokens.iconSizeM,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Equipos desbalanceados',
                  style: TextStyle(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: DesignTokens.accentColor,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  'La diferencia entre equipos es mayor a 1 jugador. Puedes continuar de todas formas.',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: DesignTokens.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Envia la solicitud de confirmacion
  void _confirmarEquipos(BuildContext context) {
    context.read<AsignacionesBloc>().add(
      ConfirmarEquiposEvent(fechaId: fechaId),
    );
  }
}

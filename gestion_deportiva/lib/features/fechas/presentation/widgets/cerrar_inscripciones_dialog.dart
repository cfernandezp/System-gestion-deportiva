import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/fecha_detalle_model.dart';
import '../bloc/cerrar_inscripciones/cerrar_inscripciones.dart';

/// Dialog de confirmacion para cerrar inscripciones de una fecha
/// E003-HU-004: Cerrar Inscripciones
/// CA-002: Resumen con cantidad de inscritos y formato de juego
/// CA-003: Advertencia si hay menos de 6 jugadores (no bloqueante)
/// CA-004: Estado actualizado a 'cerrada'
class CerrarInscripcionesDialog extends StatelessWidget {
  /// Detalle de la fecha a cerrar inscripciones
  final FechaDetalleModel fechaDetalle;

  /// Callback cuando se cierra exitosamente
  final VoidCallback? onSuccess;

  const CerrarInscripcionesDialog({
    super.key,
    required this.fechaDetalle,
    this.onSuccess,
  });

  /// Muestra el dialog de cerrar inscripciones
  /// Mobile: BottomSheet
  /// Desktop: Dialog centrado
  static Future<void> show(
    BuildContext context, {
    required FechaDetalleModel fechaDetalle,
    VoidCallback? onSuccess,
  }) async {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // Mobile: BottomSheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BlocProvider(
          create: (context) => sl<CerrarInscripcionesBloc>(),
          child: CerrarInscripcionesDialog(
            fechaDetalle: fechaDetalle,
            onSuccess: onSuccess,
          ),
        ),
      );
    } else {
      // Desktop: Dialog centrado
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => BlocProvider(
          create: (context) => sl<CerrarInscripcionesBloc>(),
          child: Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
                maxHeight: 600,
              ),
              child: CerrarInscripcionesDialog(
                fechaDetalle: fechaDetalle,
                onSuccess: onSuccess,
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

    return BlocConsumer<CerrarInscripcionesBloc, CerrarInscripcionesState>(
      listener: (context, state) {
        if (state is CerrarInscripcionesSuccess) {
          // Cerrar el dialog
          Navigator.of(context).pop();

          // Mostrar mensaje de exito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: DesignTokens.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Callback de exito
          onSuccess?.call();
        }

        if (state is CerrarInscripcionesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: DesignTokens.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is CerrarInscripcionesLoading;

        if (isMobile) {
          return _buildBottomSheetContent(context, colorScheme, isLoading);
        } else {
          return _buildDialogContent(context, colorScheme, isLoading);
        }
      },
    );
  }

  /// RN-003: Verifica si hay menos de 6 jugadores (minimo recomendado)
  bool get _tienePocosJugadores => fechaDetalle.totalInscritos < 6;

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
                  Icons.lock,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeL,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    'Cerrar Inscripciones',
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
                      onPressed: isLoading ? null : () => _confirmarCierre(context),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock),
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
                    Icons.lock,
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
                        'Cerrar Inscripciones',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      Text(
                        'No se aceptaran mas jugadores',
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
                  onPressed: isLoading ? null : () => _confirmarCierre(context),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock),
                  label: const Text('Confirmar Cierre'),
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
    final fecha = fechaDetalle.fecha;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Descripcion
        Text(
          'Estas a punto de cerrar las inscripciones para esta fecha. Una vez cerradas:',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: DesignTokens.spacingM),

        // Lista de consecuencias
        _buildConsequenceItem(
          context,
          icon: Icons.person_off,
          text: 'No se podran anotar mas jugadores',
        ),
        _buildConsequenceItem(
          context,
          icon: Icons.notifications_active,
          text: 'Los inscritos recibiran una notificacion',
        ),
        _buildConsequenceItem(
          context,
          icon: Icons.lock_open,
          text: 'Podras reabrir las inscripciones si lo necesitas',
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // CA-002: Resumen de la fecha
        Text(
          'Resumen de la fecha',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),

        const SizedBox(height: DesignTokens.spacingS),

        Container(
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
              // Fecha y hora
              _buildResumenRow(
                context,
                icon: Icons.calendar_today,
                label: 'Fecha',
                value: '${fecha.fechaFormato} - ${fecha.horaFormato}',
              ),
              const SizedBox(height: DesignTokens.spacingS),

              // Lugar
              _buildResumenRow(
                context,
                icon: Icons.location_on,
                label: 'Lugar',
                value: fecha.lugar,
              ),
              const SizedBox(height: DesignTokens.spacingS),

              // CA-002: Cantidad de inscritos
              _buildResumenRow(
                context,
                icon: Icons.people,
                label: 'Jugadores inscritos',
                value: '${fechaDetalle.totalInscritos} jugador${fechaDetalle.totalInscritos != 1 ? 'es' : ''}',
                destacado: true,
              ),
              const SizedBox(height: DesignTokens.spacingS),

              // CA-002: Formato de juego
              _buildResumenRow(
                context,
                icon: Icons.groups,
                label: 'Formato',
                value: fecha.formatoJuego,
              ),
            ],
          ),
        ),

        // CA-003: Advertencia si hay menos de 6 jugadores
        if (_tienePocosJugadores) ...[
          const SizedBox(height: DesignTokens.spacingM),
          _buildAdvertencia(context, colorScheme),
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

  /// Fila del resumen
  Widget _buildResumenRow(
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
          size: DesignTokens.iconSizeS,
          color: destacado ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
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

  /// CA-003: Banner de advertencia por minimo de jugadores (RN-003)
  Widget _buildAdvertencia(BuildContext context, ColorScheme colorScheme) {
    final totalInscritos = fechaDetalle.totalInscritos;

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
                  'Pocos jugadores inscritos',
                  style: TextStyle(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: DesignTokens.accentColor,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  'Solo hay $totalInscritos jugador${totalInscritos != 1 ? 'es' : ''} inscrito${totalInscritos != 1 ? 's' : ''}. '
                  'Se recomiendan minimo 6 para poder formar equipos.',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: DesignTokens.accentColor,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  'Puedes continuar de todas formas.',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontStyle: FontStyle.italic,
                    color: DesignTokens.accentColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Envia la solicitud de cierre
  void _confirmarCierre(BuildContext context) {
    context.read<CerrarInscripcionesBloc>().add(
      CerrarInscripcionesSubmitEvent(fechaId: fechaDetalle.fecha.fechaId),
    );
  }
}

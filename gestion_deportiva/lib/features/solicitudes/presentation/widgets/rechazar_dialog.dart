import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';

/// Dialog para confirmar rechazo de usuario
/// E001-HU-006: CA-006 - Rechazar con motivo opcional
/// CA-008: Dialogos de confirmacion
class RechazarDialog extends StatefulWidget {
  const RechazarDialog({
    super.key,
    required this.nombreUsuario,
    required this.onConfirmar,
  });

  /// Nombre del usuario a rechazar
  final String nombreUsuario;

  /// Callback al confirmar con el motivo opcional
  final void Function(String? motivo) onConfirmar;

  /// Muestra el dialog y retorna true si confirmo, false/null si cancelo
  /// El motivo se pasa al callback onConfirmar
  static Future<bool?> show({
    required BuildContext context,
    required String nombreUsuario,
    required void Function(String? motivo) onConfirmar,
  }) async {
    bool? confirmado;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RechazarDialog(
        nombreUsuario: nombreUsuario,
        onConfirmar: (motivo) {
          confirmado = true;
          onConfirmar(motivo);
          Navigator.of(dialogContext).pop();
        },
      ),
    );

    return confirmado;
  }

  @override
  State<RechazarDialog> createState() => _RechazarDialogState();
}

class _RechazarDialogState extends State<RechazarDialog> {
  final _motivoController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _motivoController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titulo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spacingS),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Icon(
                        Icons.cancel_outlined,
                        color: colorScheme.onErrorContainer,
                        size: DesignTokens.iconSizeL,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        'Rechazar solicitud',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingS),

                // Subtitulo
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(text: 'Estas por rechazar la solicitud de '),
                      TextSpan(
                        text: widget.nombreUsuario,
                        style: const TextStyle(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingL),

                // Campo de motivo (opcional)
                Text(
                  'Motivo del rechazo (opcional)',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingS),
                TextField(
                  controller: _motivoController,
                  focusNode: _focusNode,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Ej: Datos incompletos, email invalido...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingM),

                // Advertencia
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: colorScheme.error,
                        size: DesignTokens.iconSizeM,
                      ),
                      const SizedBox(width: DesignTokens.spacingS),
                      Expanded(
                        child: Text(
                          'Esta accion no se puede deshacer',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: DesignTokens.fontWeightMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingL),

                // Botones de accion
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancelar',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingM),
                    Expanded(
                      child: AppButton(
                        label: 'Rechazar',
                        variant: AppButtonVariant.danger,
                        icon: Icons.cancel,
                        onPressed: () {
                          final motivo = _motivoController.text.trim();
                          widget.onConfirmar(motivo.isEmpty ? null : motivo);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

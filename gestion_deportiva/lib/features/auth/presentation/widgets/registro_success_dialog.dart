import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

/// Dialogo de registro exitoso
/// Implementa CA-005: Pantalla de exito mostrando "Pendiente de aprobacion"
class RegistroSuccessDialog extends StatelessWidget {
  const RegistroSuccessDialog({
    super.key,
    required this.mensaje,
    this.onDismiss,
  });

  /// Mensaje a mostrar (viene del backend)
  final String mensaje;

  /// Callback al cerrar el dialogo
  final VoidCallback? onDismiss;

  /// Muestra el dialogo
  static Future<void> show(
    BuildContext context, {
    required String mensaje,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => RegistroSuccessDialog(
        mensaje: mensaje,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    // Ancho responsivo
    final dialogWidth = size.width > DesignTokens.breakpointMobile
        ? 400.0
        : size.width * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          boxShadow: DesignTokens.shadowLg,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de exito con animacion
                _SuccessIcon(),
                const SizedBox(height: DesignTokens.spacingL),

                // Titulo
                Text(
                  'Registro exitoso',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingM),

                // Badge de estado pendiente
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingM,
                    vertical: DesignTokens.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.enCurso.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                    border: Border.all(
                      color: AppColors.enCurso.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: DesignTokens.iconSizeS,
                        color: AppColors.enCurso,
                      ),
                      const SizedBox(width: DesignTokens.spacingS),
                      Text(
                        'Pendiente de aprobacion',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: AppColors.enCurso,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingL),

                // Mensaje
                Text(
                  mensaje.isNotEmpty
                      ? mensaje
                      : 'Tu cuenta ha sido creada exitosamente. Un administrador revisara tu solicitud y recibiras una notificacion cuando sea aprobada.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingS),

                // Informacion adicional
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: DesignTokens.iconSizeM,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: DesignTokens.spacingS),
                      Expanded(
                        child: Text(
                          'Podras iniciar sesion una vez que tu cuenta sea aprobada.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXl),

                // Boton de accion
                AppButton(
                  label: 'Entendido',
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar dialogo
                    onDismiss?.call();
                  },
                  isExpanded: true,
                  icon: Icons.check,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icono de exito con animacion
class _SuccessIcon extends StatefulWidget {
  @override
  State<_SuccessIcon> createState() => _SuccessIconState();
}

class _SuccessIconState extends State<_SuccessIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.animSlow,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.victoria.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.victoria,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.victoria.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget que muestra los 5 requisitos de contrasena con indicadores visuales
/// Implementa CA-003: Indicador visual de requisitos de contrasena
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.erroresBackend = const [],
  });

  /// Contrasena actual para validar
  final String password;

  /// Errores que vienen del backend (para sincronizar estado)
  final List<String> erroresBackend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Lista de requisitos con sus validaciones
    final requisitos = _getRequisitos();

    // Contar cumplidos
    final cumplidos = requisitos.where((r) => r.cumplido).length;
    final total = requisitos.length;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con barra de progreso
          Row(
            children: [
              Icon(
                Icons.security_outlined,
                size: DesignTokens.iconSizeS,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Text(
                  'Seguridad de contrasena',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$cumplidos/$total',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: _getProgressColor(cumplidos, total),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            child: LinearProgressIndicator(
              value: password.isEmpty ? 0 : cumplidos / total,
              backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(cumplidos, total),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),

          // Lista de requisitos
          ...requisitos.map((requisito) => _RequisitoItem(
                texto: requisito.texto,
                cumplido: requisito.cumplido,
                mostrarEstado: password.isNotEmpty,
              )),
        ],
      ),
    );
  }

  /// Obtiene la lista de requisitos con su estado
  List<_Requisito> _getRequisitos() {
    return [
      _Requisito(
        texto: 'Minimo 8 caracteres',
        cumplido: password.length >= 8,
      ),
      _Requisito(
        texto: 'Al menos una letra mayuscula',
        cumplido: password.contains(RegExp(r'[A-Z]')),
      ),
      _Requisito(
        texto: 'Al menos una letra minuscula',
        cumplido: password.contains(RegExp(r'[a-z]')),
      ),
      _Requisito(
        texto: 'Al menos un numero',
        cumplido: password.contains(RegExp(r'[0-9]')),
      ),
      _Requisito(
        texto: 'Al menos un caracter especial (!@#\$%^&*)',
        cumplido: password.contains(RegExp(r'[!@#$%^&*]')),
      ),
    ];
  }

  /// Retorna el color segun el progreso
  Color _getProgressColor(int cumplidos, int total) {
    if (cumplidos == 0) return AppColors.empate;
    if (cumplidos < 3) return AppColors.derrota;
    if (cumplidos < 5) return AppColors.enCurso;
    return AppColors.victoria;
  }
}

/// Modelo interno para un requisito
class _Requisito {
  final String texto;
  final bool cumplido;

  const _Requisito({
    required this.texto,
    required this.cumplido,
  });
}

/// Widget para mostrar un item de requisito
class _RequisitoItem extends StatelessWidget {
  const _RequisitoItem({
    required this.texto,
    required this.cumplido,
    this.mostrarEstado = true,
  });

  final String texto;
  final bool cumplido;
  final bool mostrarEstado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determinar colores e iconos
    final Color iconColor;
    final IconData iconData;
    final Color textColor;

    if (!mostrarEstado) {
      // Sin estado (contrasena vacia)
      iconColor = colorScheme.outline;
      iconData = Icons.circle_outlined;
      textColor = colorScheme.onSurfaceVariant;
    } else if (cumplido) {
      // Cumplido
      iconColor = AppColors.victoria;
      iconData = Icons.check_circle;
      textColor = colorScheme.onSurface;
    } else {
      // No cumplido
      iconColor = colorScheme.outline;
      iconData = Icons.circle_outlined;
      textColor = colorScheme.onSurfaceVariant;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingXs),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: DesignTokens.animFast,
            child: Icon(
              iconData,
              key: ValueKey(cumplido && mostrarEstado),
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              texto,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: cumplido && mostrarEstado
                    ? DesignTokens.fontWeightMedium
                    : DesignTokens.fontWeightRegular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

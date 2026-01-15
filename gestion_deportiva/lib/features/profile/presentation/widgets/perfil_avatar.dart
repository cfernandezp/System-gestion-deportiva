import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Widget de avatar para el perfil
/// RN-003: Si la foto no esta registrada, mostrar imagen generica
class PerfilAvatar extends StatelessWidget {
  final String? fotoUrl;
  final String nombreCompleto;
  final double size;

  const PerfilAvatar({
    super.key,
    this.fotoUrl,
    required this.nombreCompleto,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Obtener iniciales del nombre
    final iniciales = _getIniciales(nombreCompleto);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: DesignTokens.primaryGradient,
        boxShadow: isDark ? DesignTokens.shadowMdDark : DesignTokens.shadowMd,
      ),
      child: fotoUrl != null && fotoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                fotoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(colorScheme, iniciales);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLoadingIndicator(colorScheme);
                },
              ),
            )
          : _buildPlaceholder(colorScheme, iniciales),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme, String iniciales) {
    return Center(
      child: Text(
        iniciales,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35,
          fontWeight: DesignTokens.fontWeightBold,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ColorScheme colorScheme) {
    return Center(
      child: SizedBox(
        width: size * 0.3,
        height: size * 0.3,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getIniciales(String nombre) {
    if (nombre.isEmpty) return '?';

    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return partes[0][0].toUpperCase();
  }
}

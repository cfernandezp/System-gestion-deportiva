import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Widget de avatar para jugador
/// E002-HU-003: CA-002, RN-002
/// Muestra foto o avatar generico con iniciales
class JugadorAvatar extends StatelessWidget {
  final String? fotoUrl;
  final String nombreCompleto;
  final double size;

  const JugadorAvatar({
    super.key,
    this.fotoUrl,
    required this.nombreCompleto,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iniciales = _obtenerIniciales();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: fotoUrl == null ? DesignTokens.primaryGradient : null,
        boxShadow: DesignTokens.shadowSm,
      ),
      child: fotoUrl != null && fotoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                fotoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialsAvatar(colorScheme, iniciales);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            )
          : _buildInitialsAvatar(colorScheme, iniciales),
    );
  }

  Widget _buildInitialsAvatar(ColorScheme colorScheme, String iniciales) {
    return Center(
      child: Text(
        iniciales,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: DesignTokens.fontWeightBold,
        ),
      ),
    );
  }

  String _obtenerIniciales() {
    final palabras = nombreCompleto.trim().split(' ');
    if (palabras.isEmpty) return '?';
    if (palabras.length == 1) {
      return palabras[0].isNotEmpty ? palabras[0][0].toUpperCase() : '?';
    }
    final primera = palabras[0].isNotEmpty ? palabras[0][0] : '';
    final ultima = palabras[palabras.length - 1].isNotEmpty
        ? palabras[palabras.length - 1][0]
        : '';
    return '$primera$ultima'.toUpperCase();
  }
}

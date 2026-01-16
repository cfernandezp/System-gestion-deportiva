import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Barra de busqueda para jugadores
/// E002-HU-003: CA-003, RN-003
class JugadoresSearchBar extends StatefulWidget {
  final String? valorInicial;
  final ValueChanged<String> onBuscar;
  final VoidCallback onLimpiar;

  const JugadoresSearchBar({
    super.key,
    this.valorInicial,
    required this.onBuscar,
    required this.onLimpiar,
  });

  @override
  State<JugadoresSearchBar> createState() => _JugadoresSearchBarState();
}

class _JugadoresSearchBarState extends State<JugadoresSearchBar> {
  late final TextEditingController _controller;
  bool _tieneTexto = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorInicial);
    _tieneTexto = widget.valorInicial?.isNotEmpty ?? false;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final tieneTexto = _controller.text.isNotEmpty;
    if (tieneTexto != _tieneTexto) {
      setState(() {
        _tieneTexto = tieneTexto;
      });
    }
  }

  void _onSubmit(String valor) {
    widget.onBuscar(valor);
  }

  void _onLimpiar() {
    _controller.clear();
    widget.onLimpiar();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o apodo...',
        prefixIcon: Icon(
          Icons.search,
          color: colorScheme.onSurfaceVariant,
        ),
        suffixIcon: _tieneTexto
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: _onLimpiar,
                tooltip: 'Limpiar busqueda',
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: _onSubmit,
      onChanged: (valor) {
        // Busqueda en tiempo real con debounce
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_controller.text == valor) {
            widget.onBuscar(valor);
          }
        });
      },
    );
  }
}

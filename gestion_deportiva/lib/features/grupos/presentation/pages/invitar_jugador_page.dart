import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../bloc/invitar_jugador/invitar_jugador_bloc.dart';
import '../bloc/invitar_jugador/invitar_jugador_event.dart';
import '../bloc/invitar_jugador/invitar_jugador_state.dart';

/// E001-HU-004: Pantalla para invitar jugador al grupo
/// CA-001, CA-006, CA-007: Formulario celular + validacion + confirmacion
/// Patron mobile: Pantalla completa con formulario
class InvitarJugadorPage extends StatefulWidget {
  final String grupoId;

  const InvitarJugadorPage({super.key, required this.grupoId});

  @override
  State<InvitarJugadorPage> createState() => _InvitarJugadorPageState();
}

class _InvitarJugadorPageState extends State<InvitarJugadorPage> {
  final _formKey = GlobalKey<FormState>();
  final _celularController = TextEditingController();

  @override
  void dispose() {
    _celularController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitar Jugador'),
        centerTitle: true,
      ),
      body: BlocListener<InvitarJugadorBloc, InvitarJugadorState>(
        listener: (context, state) {
          if (state is InvitarJugadorSuccess) {
            // CA-007: Mostrar confirmacion con recordatorio
            _showSuccessDialog(context, state);
          } else if (state is InvitarJugadorError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono y descripcion
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: 40,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingL),
                  Text(
                    'Invitar un nuevo jugador',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spacingS),
                  Text(
                    'Ingresa el numero de celular del jugador que deseas invitar a tu grupo.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spacingXl),

                  // CA-006: Campo celular con validacion
                  TextFormField(
                    controller: _celularController,
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Numero de celular',
                      hintText: '9XXXXXXXX',
                      prefixIcon: const Icon(Icons.phone_android),
                      prefixText: '+51 ',
                      counterText: '',
                      helperText: 'Formato: 9 digitos, debe iniciar con 9',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      ),
                    ),
                    validator: _validateCelular,
                  ),
                  const SizedBox(height: DesignTokens.spacingXl),

                  // Boton invitar
                  BlocBuilder<InvitarJugadorBloc, InvitarJugadorState>(
                    builder: (context, state) {
                      final isLoading = state is InvitarJugadorLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: isLoading ? null : _onInvitar,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(isLoading ? 'Invitando...' : 'Invitar Jugador'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: DesignTokens.spacingXl),

                  // RN-006: Info de notificacion manual
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spacingM),
                    decoration: BoxDecoration(
                      color: DesignTokens.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      border: Border.all(
                        color: DesignTokens.accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: DesignTokens.accentColor,
                        ),
                        const SizedBox(width: DesignTokens.spacingS),
                        Expanded(
                          child: Text(
                            'El sistema NO envia notificaciones automaticas. Debes avisar al jugador por WhatsApp, llamada o en persona para que descargue la app y active su cuenta.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// CA-006: Validacion de formato celular
  String? _validateCelular(String? value) {
    if (value == null || value.isEmpty) {
      return 'El celular es obligatorio';
    }
    if (value.length != 9) {
      return 'Debe tener exactamente 9 digitos';
    }
    if (!value.startsWith('9')) {
      return 'Debe iniciar con el digito 9';
    }
    return null;
  }

  void _onInvitar() {
    if (_formKey.currentState?.validate() == true) {
      context.read<InvitarJugadorBloc>().add(
            InvitarJugadorSubmitEvent(
              grupoId: widget.grupoId,
              celular: _celularController.text.trim(),
            ),
          );
    }
  }

  /// CA-007 / RN-006: Dialog de confirmacion con recordatorio
  void _showSuccessDialog(BuildContext context, InvitarJugadorSuccess state) {
    final response = state.response;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: DesignTokens.successColor,
          size: 48,
        ),
        title: const Text('Jugador Invitado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(response.message),
            const SizedBox(height: DesignTokens.spacingM),
            // Info del jugador invitado
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.phone,
                    label: 'Celular',
                    value: response.celular,
                  ),
                  if (response.nombre.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.spacingS),
                    _InfoTile(
                      icon: Icons.person,
                      label: 'Nombre',
                      value: response.nombre,
                    ),
                  ],
                  const SizedBox(height: DesignTokens.spacingS),
                  _InfoTile(
                    icon: response.esNuevo ? Icons.schedule : Icons.check_circle,
                    label: 'Estado',
                    value: response.esNuevo
                        ? 'Pendiente de activacion'
                        : 'Activo (ya tenia cuenta)',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.pop(); // Volver a la lista de miembros
            },
            child: const Text('Aceptar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Limpiar formulario para invitar otro
              _celularController.clear();
            },
            child: const Text('Invitar Otro'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

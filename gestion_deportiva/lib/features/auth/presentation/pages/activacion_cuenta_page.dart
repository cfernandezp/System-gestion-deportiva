import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/activacion_cuenta/activacion_cuenta_bloc.dart';
import '../bloc/activacion_cuenta/activacion_cuenta_event.dart';
import '../bloc/activacion_cuenta/activacion_cuenta_state.dart';

/// E001-HU-005: Pantalla de Activacion de Cuenta de Jugador Invitado
///
/// Flujo de 2 pasos:
/// 1. Ingresar celular -> Verificar invitacion pendiente
/// 2. Ingresar nombre + contrasena -> Activar cuenta
///
/// Accesible desde login: "Fui invitado a un grupo"
class ActivacionCuentaPage extends StatelessWidget {
  const ActivacionCuentaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ActivacionCuentaBloc>(),
      child: const _ActivacionCuentaView(),
    );
  }
}

class _ActivacionCuentaView extends StatefulWidget {
  const _ActivacionCuentaView();

  @override
  State<_ActivacionCuentaView> createState() => _ActivacionCuentaViewState();
}

class _ActivacionCuentaViewState extends State<_ActivacionCuentaView> {
  // Controllers paso 1
  final _celularController = TextEditingController();

  // Controllers paso 2
  final _nombreController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes
  final _celularFocus = FocusNode();
  final _nombreFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // Celular verificado (guardado del paso 1)
  String _celularVerificado = '';

  @override
  void dispose() {
    _celularController.dispose();
    _nombreController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _celularFocus.dispose();
    _nombreFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < DesignTokens.breakpointMobile;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Activar Cuenta'),
        centerTitle: true,
      ),
      body: BlocConsumer<ActivacionCuentaBloc, ActivacionCuentaState>(
        listener: (context, state) {
          if (state is ActivacionCuentaSuccess) {
            // CA-006: Redirigir al login
            _showSuccessDialog(context, state);
          } else if (state is ActivacionCuentaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(DesignTokens.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
              ),
            );
          } else if (state is InvitacionVerificada) {
            // Guardar celular verificado para paso 2
            _celularVerificado = state.celular;
          } else if (state is InvitacionNoEncontrada) {
            // CA-002 / CA-004: Mostrar mensaje
            _showInfoDialog(context, state);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile
                      ? DesignTokens.spacingM
                      : DesignTokens.spacingL,
                  vertical: DesignTokens.spacingL,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header
                      _buildHeader(theme, colorScheme),
                      const SizedBox(height: DesignTokens.spacingXl),

                      // Contenido segun estado
                      if (state is InvitacionVerificada)
                        _buildPaso2Activacion(
                          context, theme, colorScheme, isMobile, state,
                        )
                      else
                        _buildPaso1Celular(
                          context, theme, colorScheme, isMobile, state,
                        ),

                      const SizedBox(height: DesignTokens.spacingL),

                      // Link volver al login
                      _buildVolverLoginLink(theme, state is ActivacionCuentaLoading),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Header con icono
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: DesignTokens.primaryGradient,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_alt_1,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          'Activar mi cuenta',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          'Si fuiste invitado a un grupo, activa tu cuenta aqui',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Paso 1: Ingresar celular para verificar invitacion
  Widget _buildPaso1Celular(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    ActivacionCuentaState state,
  ) {
    final isLoading = state is ActivacionCuentaLoading;

    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indicador de paso
          _buildPasoIndicador(theme, colorScheme, 1),
          const SizedBox(height: DesignTokens.spacingM),

          Text(
            'Verifica tu invitacion',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Ingresa el celular con el que te invitaron al grupo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Campo celular
          AppTextField.number(
            controller: _celularController,
            focusNode: _celularFocus,
            label: 'Numero de celular',
            hint: '9XXXXXXXX',
            prefixIcon: Icons.phone_android,
            maxLength: 9,
            enabled: !isLoading,
            onSubmitted: (_) => _onVerificarInvitacion(),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Boton verificar
          AppButton(
            label: 'Verificar invitacion',
            onPressed: isLoading ? null : _onVerificarInvitacion,
            isLoading: isLoading,
            loadingLabel: 'Verificando...',
            isExpanded: true,
            icon: Icons.search,
          ),
        ],
      ),
    );
  }

  /// Paso 2: Ingresar nombre y contrasena para activar
  Widget _buildPaso2Activacion(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    InvitacionVerificada state,
  ) {
    return BlocBuilder<ActivacionCuentaBloc, ActivacionCuentaState>(
      builder: (context, currentState) {
        final isLoading = currentState is ActivacionCuentaLoading;

        return AppCard(
          variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
          margin: EdgeInsets.zero,
          padding: EdgeInsets.all(
            isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicador de paso
              _buildPasoIndicador(theme, colorScheme, 2),
              const SizedBox(height: DesignTokens.spacingM),

              Text(
                'Completa tu registro',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacingS),

              // Info invitacion
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingS),
                decoration: BoxDecoration(
                  color: DesignTokens.successColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  border: Border.all(
                    color: DesignTokens.successColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: DesignTokens.successColor,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        state.verificacion.mensaje,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.spacingL),

              // CA-005 / RN-005: Campo nombre
              AppTextField(
                controller: _nombreController,
                focusNode: _nombreFocus,
                label: 'Nombre completo',
                hint: 'Ej: Juan Perez',
                prefixIcon: Icons.person,
                enabled: !isLoading,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: DesignTokens.spacingM),

              // CA-003 / RN-002: Campo contrasena
              AppTextField.password(
                controller: _passwordController,
                focusNode: _passwordFocus,
                label: 'Contrasena',
                helperText: 'Min. 8 caracteres, mayuscula, minuscula, numero y caracter especial',
                enabled: !isLoading,
                onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
              ),
              const SizedBox(height: DesignTokens.spacingM),

              // Confirmar contrasena
              AppTextField.password(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                label: 'Confirmar contrasena',
                enabled: !isLoading,
                onSubmitted: (_) => _onActivarCuenta(),
              ),
              const SizedBox(height: DesignTokens.spacingL),

              // Boton activar
              AppButton(
                label: 'Activar cuenta',
                onPressed: isLoading ? null : _onActivarCuenta,
                isLoading: isLoading,
                loadingLabel: 'Activando cuenta...',
                isExpanded: true,
                icon: Icons.check_circle,
              ),

              const SizedBox(height: DesignTokens.spacingM),

              // Boton volver al paso 1
              TextButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        context.read<ActivacionCuentaBloc>().add(const ResetActivacionEvent());
                      },
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Cambiar celular'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Indicador visual de paso (1 de 2 o 2 de 2)
  Widget _buildPasoIndicador(
    ThemeData theme,
    ColorScheme colorScheme,
    int paso,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPasoDot(colorScheme, true),
        Container(
          width: 40,
          height: 2,
          color: paso >= 2
              ? colorScheme.primary
              : colorScheme.outlineVariant,
        ),
        _buildPasoDot(colorScheme, paso >= 2),
      ],
    );
  }

  Widget _buildPasoDot(ColorScheme colorScheme, bool activo) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: activo ? colorScheme.primary : colorScheme.outlineVariant,
      ),
    );
  }

  /// Link para volver al login
  Widget _buildVolverLoginLink(ThemeData theme, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Ya tienes cuenta?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: isLoading ? null : () => context.go('/login'),
          child: Text(
            'Iniciar sesion',
            style: TextStyle(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ),
      ],
    );
  }

  /// Paso 1: Verificar invitacion
  void _onVerificarInvitacion() {
    final celular = _celularController.text.trim();

    // Validacion local basica
    if (celular.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu numero de celular')),
      );
      return;
    }
    if (celular.length != 9 || !celular.startsWith('9')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El celular debe tener 9 digitos y empezar con 9'),
        ),
      );
      return;
    }

    context.read<ActivacionCuentaBloc>().add(
          VerificarInvitacionEvent(celular: celular),
        );
  }

  /// Paso 2: Activar cuenta
  void _onActivarCuenta() {
    final nombre = _nombreController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validaciones locales
    if (nombre.isEmpty || nombre.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre debe tener al menos 2 caracteres'),
        ),
      );
      return;
    }

    // CA-003 / RN-002: Validacion de contrasena
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contrasena debe tener al menos 8 caracteres'),
        ),
      );
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contrasena debe tener al menos una mayuscula'),
        ),
      );
      return;
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contrasena debe tener al menos una minuscula'),
        ),
      );
      return;
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contrasena debe tener al menos un numero'),
        ),
      );
      return;
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contrasena debe tener al menos un caracter especial'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contrasenas no coinciden'),
        ),
      );
      return;
    }

    context.read<ActivacionCuentaBloc>().add(
          ActivarCuentaEvent(
            celular: _celularVerificado,
            nombreCompleto: nombre,
            password: password,
          ),
        );
  }

  /// CA-006: Dialog de exito con redireccion al login
  void _showSuccessDialog(
    BuildContext context,
    ActivacionCuentaSuccess state,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: DesignTokens.successColor,
          size: 48,
        ),
        title: const Text('Cuenta Activada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.response.mensaje),
            const SizedBox(height: DesignTokens.spacingM),
            if (state.response.gruposActivos > 0)
              Text(
                'Tienes acceso a ${state.response.gruposActivos} grupo(s)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // CA-006: Redirigir al login
              context.go('/login');
            },
            child: const Text('Iniciar sesion'),
          ),
        ],
      ),
    );
  }

  /// CA-002 / CA-004: Dialog informativo
  void _showInfoDialog(
    BuildContext context,
    InvitacionNoEncontrada state,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          state.yaActivo ? Icons.info_outline : Icons.warning_amber,
          color: state.yaActivo
              ? Theme.of(context).colorScheme.primary
              : Colors.orange,
          size: 48,
        ),
        title: Text(state.yaActivo ? 'Cuenta Activa' : 'Sin Invitacion'),
        content: Text(state.mensaje),
        actions: [
          if (state.yaActivo)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/login');
              },
              child: const Text('Ir al login'),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
        ],
      ),
    );
  }
}

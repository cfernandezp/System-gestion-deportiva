import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/login/login.dart';
import '../bloc/session/session.dart';

/// Pagina de inicio de sesion
/// Implementa HU-002: Inicio de Sesion
///
/// Criterios de Aceptacion:
/// - CA-001: Formulario con email y contrasena
/// - CA-002: Login exitoso -> navegar a home
/// - CA-003: Mostrar error generico si credenciales invalidas
/// - CA-004: Validar campos obligatorios
/// - CA-005: Link a registro
/// - CA-006: Link a recuperacion de contrasena
///
/// Layout Responsive:
/// - Mobile (<600px): Formulario ocupa ancho completo con padding
/// - Tablet/Desktop (>=600px): Card centrada con ancho maximo 420px
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LoginBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus nodes para navegacion
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // Errores de validacion
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onSubmit() {
    // Limpiar errores previos
    setState(() {
      _fieldErrors = {};
    });

    context.read<LoginBloc>().add(
          LoginSubmitEvent(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    // Determinar si es mobile o tablet/desktop
    final isMobile = size.width < DesignTokens.breakpointMobile;
    final maxFormWidth = 420.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            // CA-002: Login exitoso
            // 1. Actualizar SessionBloc con datos del usuario autenticado
            context.read<SessionBloc>().add(
                  SessionAuthenticatedEvent(
                    usuarioId: state.response.usuarioId,
                    nombreCompleto: state.response.nombreCompleto,
                    email: state.response.email,
                    rol: state.response.rol,
                  ),
                );
            // 2. Navegar a home
            context.go('/');
          } else if (state is LoginError) {
            // CA-003: Mostrar mensaje de error apropiado
            _mostrarErrorSnackBar(context, state);
          } else if (state is LoginValidationError) {
            // CA-004: Actualizar errores de campo
            setState(() {
              _fieldErrors = state.errores;
            });
          } else if (state is LoginBloqueoInfo && state.bloqueado) {
            // RN-007: Mostrar mensaje de bloqueo
            _mostrarBloqueoSnackBar(context, state);
          }
        },
        builder: (context, state) {
          final isLoading = state is LoginLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
                  vertical: DesignTokens.spacingL,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header con logo/icono
                      _buildHeader(theme, colorScheme),
                      const SizedBox(height: DesignTokens.spacingXl),

                      // CA-001: Formulario en Card
                      AppCard(
                        variant: isMobile
                            ? AppCardVariant.standard
                            : AppCardVariant.elevated,
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.all(
                          isMobile
                              ? DesignTokens.spacingM
                              : DesignTokens.spacingL,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Titulo del formulario
                              Text(
                                'Iniciar sesion',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: DesignTokens.fontWeightBold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignTokens.spacingS),
                              Text(
                                'Ingresa tus credenciales para acceder',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: DesignTokens.spacingL),

                              // CA-001: Campo Email
                              AppTextField.email(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                errorText: _fieldErrors['email'],
                                enabled: !isLoading,
                                onSubmitted: (_) =>
                                    _passwordFocus.requestFocus(),
                              ),
                              const SizedBox(height: DesignTokens.spacingM),

                              // CA-001: Campo Password
                              AppTextField.password(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                label: 'Contrasena',
                                errorText: _fieldErrors['password'],
                                enabled: !isLoading,
                                onSubmitted: (_) => _onSubmit(),
                              ),
                              const SizedBox(height: DesignTokens.spacingS),

                              // CA-006: Link a recuperacion de contrasena (HU-003)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          context.go('/recuperar-contrasena');
                                        },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Olvidaste tu contrasena?',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: DesignTokens.spacingL),

                              // Boton de login con estado de carga
                              AppButton(
                                label: 'Iniciar sesion',
                                onPressed: isLoading ? null : _onSubmit,
                                isLoading: isLoading,
                                loadingLabel: 'Iniciando sesion...',
                                isExpanded: true,
                                icon: Icons.login,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingL),

                      // CA-005: Link a registro
                      _buildRegistroLink(theme, isLoading),
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

  /// Header con icono/logo de la app
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Icono de la app
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
            Icons.sports_soccer,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          'Gestion Deportiva',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// CA-005: Link para ir a registro
  Widget _buildRegistroLink(ThemeData theme, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'No tienes cuenta?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  context.go('/registro');
                },
          child: Text(
            'Registrate',
            style: TextStyle(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ),
      ],
    );
  }

  /// CA-003: Muestra SnackBar con mensaje de error apropiado
  /// RN-002, RN-004, RN-007: Mensajes diferenciados segun tipo de error
  void _mostrarErrorSnackBar(BuildContext context, LoginError state) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color backgroundColor;

    switch (state.errorType) {
      case LoginErrorType.credencialesInvalidas:
        icon = Icons.lock_outline;
        backgroundColor = colorScheme.error;
        break;
      case LoginErrorType.cuentaPendiente:
        icon = Icons.hourglass_empty;
        backgroundColor = Colors.orange;
        break;
      case LoginErrorType.cuentaRechazada:
        icon = Icons.cancel_outlined;
        backgroundColor = colorScheme.error;
        break;
      case LoginErrorType.cuentaBloqueada:
        icon = Icons.timer_outlined;
        backgroundColor = Colors.orange;
        break;
      case LoginErrorType.validacion:
        icon = Icons.warning_amber;
        backgroundColor = Colors.orange;
        break;
      case LoginErrorType.servidor:
        icon = Icons.cloud_off;
        backgroundColor = colorScheme.error;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(child: Text(state.message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(DesignTokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        duration: state.errorType == LoginErrorType.cuentaPendiente ||
                state.errorType == LoginErrorType.cuentaRechazada
            ? const Duration(seconds: 5)
            : const Duration(seconds: 4),
      ),
    );
  }

  /// RN-007: Muestra SnackBar con informacion de bloqueo
  void _mostrarBloqueoSnackBar(BuildContext context, LoginBloqueoInfo state) {
    final mensaje = state.minutosRestantes != null
        ? 'Cuenta bloqueada. Intenta en ${state.minutosRestantes} minutos.'
        : 'Cuenta bloqueada temporalmente.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(DesignTokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

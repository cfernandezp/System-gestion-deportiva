import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/recuperacion/recuperacion.dart';
import '../widgets/password_strength_indicator.dart';

/// Pagina para restablecer contrasena con token
/// Implementa HU-003: Recuperacion de Contrasena
///
/// Criterios de Aceptacion:
/// - CA-004: Enlace valido permite establecer nueva contrasena
/// - CA-005: Enlace expirado muestra mensaje y opcion de solicitar nuevo
/// - CA-006: Nueva contrasena establecida exitosamente
///
/// Reglas de Negocio:
/// - RN-002: Token valido por 1 hora
/// - RN-003: Uso unico del token
/// - RN-004: Requisitos de contrasena + diferente a anterior
/// - RN-005: Confirmacion debe coincidir
/// - RN-006: Cierre de sesiones al cambiar contrasena
///
/// Layout Responsive:
/// - Mobile (<600px): Formulario ocupa ancho completo con padding
/// - Tablet/Desktop (>=600px): Card centrada con ancho maximo 420px
class RestablecerContrasenaPage extends StatelessWidget {
  const RestablecerContrasenaPage({
    super.key,
    required this.token,
  });

  /// Token de recuperacion de la URL
  final String token;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RecuperacionBloc>()
        ..add(ValidarTokenEvent(token: token)),
      child: _RestablecerContrasenaView(token: token),
    );
  }
}

class _RestablecerContrasenaView extends StatefulWidget {
  const _RestablecerContrasenaView({required this.token});

  final String token;

  @override
  State<_RestablecerContrasenaView> createState() =>
      _RestablecerContrasenaViewState();
}

class _RestablecerContrasenaViewState
    extends State<_RestablecerContrasenaView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // Errores de validacion
  Map<String, String> _fieldErrors = {};

  // Password actual para indicador de fuerza
  String _currentPassword = '';

  // CA-005: Error de confirmacion
  String? _confirmPasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onSubmit() {
    setState(() {
      _fieldErrors = {};
      _confirmPasswordError = null;
    });

    context.read<RecuperacionBloc>().add(
          RestablecerContrasenaEvent(
            token: widget.token,
            nuevaContrasena: _passwordController.text,
            confirmarContrasena: _confirmPasswordController.text,
          ),
        );
  }

  void _onPasswordChanged(String password) {
    setState(() {
      _currentPassword = password;
      // Validar coincidencia si ya hay confirmacion
      if (_confirmPasswordController.text.isNotEmpty) {
        _validatePasswordMatch();
      }
    });
  }

  void _onConfirmPasswordChanged(String confirmPassword) {
    _validatePasswordMatch();
  }

  // RN-005: Validar coincidencia de contrasenas
  void _validatePasswordMatch() {
    setState(() {
      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = null;
      } else if (_passwordController.text != _confirmPasswordController.text) {
        _confirmPasswordError = 'Las contrasenas no coinciden';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    final isMobile = size.width < DesignTokens.breakpointMobile;
    final maxFormWidth = 420.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<RecuperacionBloc, RecuperacionState>(
        listener: (context, state) {
          if (state is RecuperacionContrasenaActualizada) {
            // CA-006: Contrasena actualizada - mostrar exito y redirigir
            _mostrarExitoDialog(context, state);
          } else if (state is RecuperacionError) {
            // Mostrar error
            _mostrarErrorSnackBar(context, state);
          } else if (state is RecuperacionValidationError) {
            setState(() {
              _fieldErrors = state.errores;
              if (state.errores.containsKey('confirmarContrasena')) {
                _confirmPasswordError = state.errores['confirmarContrasena'];
              }
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is RecuperacionLoading;

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
                      // Header
                      _buildHeader(theme, colorScheme),
                      const SizedBox(height: DesignTokens.spacingXl),

                      // Contenido segun estado
                      _buildContent(
                        context,
                        theme,
                        colorScheme,
                        isMobile,
                        state,
                        isLoading,
                      ),

                      const SizedBox(height: DesignTokens.spacingL),

                      // Link a login
                      _buildLoginLink(theme, isLoading),
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
            Icons.password,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          'Nueva contrasena',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Contenido principal segun el estado
  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    RecuperacionState state,
    bool isLoading,
  ) {
    // Estado: Cargando validacion de token
    if (state is RecuperacionLoading && _passwordController.text.isEmpty) {
      return _buildLoadingCard(theme, colorScheme, isMobile);
    }

    // CA-005: Token invalido/expirado/usado
    if (state is RecuperacionTokenInvalido) {
      return _buildTokenInvalidoCard(
        theme,
        colorScheme,
        isMobile,
        state,
      );
    }

    // CA-004: Token valido - mostrar formulario
    if (state is RecuperacionTokenValido ||
        state is RecuperacionLoading ||
        state is RecuperacionValidationError ||
        state is RecuperacionError) {
      return _buildFormCard(
        theme,
        colorScheme,
        isMobile,
        isLoading,
        state is RecuperacionTokenValido ? state : null,
      );
    }

    // Estado inicial - cargando
    return _buildLoadingCard(theme, colorScheme, isMobile);
  }

  /// Card de carga mientras valida token
  Widget _buildLoadingCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Verificando enlace...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// CA-005: Card cuando el token es invalido/expirado/usado
  Widget _buildTokenInvalidoCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    RecuperacionTokenInvalido state,
  ) {
    IconData iconData;
    Color iconColor;
    String titulo;

    switch (state.errorType) {
      case TokenErrorType.tokenExpirado:
        iconData = Icons.timer_off;
        iconColor = DesignTokens.accentColor;
        titulo = 'Enlace expirado';
        break;
      case TokenErrorType.tokenUsado:
        iconData = Icons.check_circle_outline;
        iconColor = colorScheme.outline;
        titulo = 'Enlace ya utilizado';
        break;
      default:
        iconData = Icons.link_off;
        iconColor = colorScheme.error;
        titulo = 'Enlace invalido';
    }

    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        children: [
          // Icono
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              size: 32,
              color: iconColor,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),

          // Titulo
          Text(
            titulo,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),

          // Mensaje
          Text(
            state.mensaje,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Boton para solicitar nuevo enlace
          AppButton(
            label: 'Solicitar nuevo enlace',
            onPressed: () {
              context.go('/recuperar-contrasena');
            },
            variant: AppButtonVariant.primary,
            isExpanded: true,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  /// CA-004, CA-006: Card con formulario de nueva contrasena
  Widget _buildFormCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    bool isLoading,
    RecuperacionTokenValido? tokenState,
  ) {
    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Saludo si tenemos el nombre
            if (tokenState?.nombre != null) ...[
              Text(
                'Hola, ${tokenState!.nombre}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacingS),
            ],

            // Descripcion
            Text(
              'Ingresa tu nueva contrasena.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // Tiempo restante si esta disponible
            if (tokenState?.minutosRestantes != null) ...[
              const SizedBox(height: DesignTokens.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: DesignTokens.iconSizeS,
                      color: DesignTokens.accentColor,
                    ),
                    const SizedBox(width: DesignTokens.spacingXs),
                    Text(
                      'Enlace valido por ${tokenState!.minutosRestantes} min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.accentColor,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.spacingL),

            // Campo nueva contrasena
            AppTextField.password(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: 'Nueva contrasena',
              hint: 'Ingresa tu nueva contrasena',
              errorText: _fieldErrors['nuevaContrasena'],
              enabled: !isLoading,
              onChanged: _onPasswordChanged,
              onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
            ),
            const SizedBox(height: DesignTokens.spacingM),

            // CA-003/RN-004: Indicador de fuerza de contrasena
            PasswordStrengthIndicator(
              password: _currentPassword,
            ),
            const SizedBox(height: DesignTokens.spacingM),

            // Campo confirmar contrasena (RN-005)
            AppTextField.password(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              label: 'Confirmar contrasena',
              hint: 'Repite tu nueva contrasena',
              errorText:
                  _confirmPasswordError ?? _fieldErrors['confirmarContrasena'],
              enabled: !isLoading,
              onChanged: _onConfirmPasswordChanged,
              onSubmitted: (_) => _onSubmit(),
              // Mostrar check verde si coinciden
              showSuccessState: _confirmPasswordController.text.isNotEmpty &&
                  _passwordController.text == _confirmPasswordController.text,
            ),
            const SizedBox(height: DesignTokens.spacingXl),

            // Boton de restablecer
            AppButton(
              label: 'Restablecer contrasena',
              onPressed: isLoading ? null : _onSubmit,
              isLoading: isLoading,
              loadingLabel: 'Restableciendo...',
              isExpanded: true,
              icon: Icons.lock_reset,
            ),
          ],
        ),
      ),
    );
  }

  /// Link para volver al login
  Widget _buildLoginLink(ThemeData theme, bool disabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.arrow_back,
          size: DesignTokens.iconSizeS,
          color: disabled
              ? theme.colorScheme.outline
              : theme.colorScheme.primary,
        ),
        TextButton(
          onPressed: disabled
              ? null
              : () {
                  context.go('/login');
                },
          child: Text(
            'Volver al login',
            style: TextStyle(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ),
      ],
    );
  }

  /// CA-006: Dialog de exito al restablecer contrasena
  void _mostrarExitoDialog(
    BuildContext context,
    RecuperacionContrasenaActualizada state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de exito
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: DesignTokens.successColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 40,
                      color: DesignTokens.successColor,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingM),

                  // Titulo
                  Text(
                    'Contrasena actualizada',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spacingS),

                  // Mensaje
                  Text(
                    state.mensaje,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // RN-006: Indicador de sesiones cerradas
                  if (state.sesionesCerradas) ...[
                    const SizedBox(height: DesignTokens.spacingM),
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spacingS),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.devices,
                            size: DesignTokens.iconSizeS,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: DesignTokens.spacingS),
                          Flexible(
                            child: Text(
                              'Se cerraron todas las sesiones activas',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: DesignTokens.spacingL),

                  // Boton para ir al login
                  AppButton(
                    label: 'Iniciar sesion',
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.go('/login');
                    },
                    isExpanded: true,
                    icon: Icons.login,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra SnackBar con mensaje de error
  void _mostrarErrorSnackBar(BuildContext context, RecuperacionError state) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color backgroundColor;

    switch (state.errorType) {
      case RecuperacionErrorType.contrasenasNoCoinciden:
        icon = Icons.compare_arrows;
        backgroundColor = DesignTokens.accentColor;
        break;
      case RecuperacionErrorType.contrasenaInvalida:
        icon = Icons.security;
        backgroundColor = DesignTokens.accentColor;
        break;
      case RecuperacionErrorType.contrasenaIgualAnterior:
        icon = Icons.history;
        backgroundColor = DesignTokens.accentColor;
        break;
      default:
        icon = Icons.error_outline;
        backgroundColor = colorScheme.error;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(child: Text(state.mensaje)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(DesignTokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

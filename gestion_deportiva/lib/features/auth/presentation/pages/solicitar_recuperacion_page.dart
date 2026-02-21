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

/// E001-HU-007: Pagina de Recuperacion de Contrasena
///
/// Flujo multi-paso:
/// 1. Ingresar celular -> identificar tipo (admin/jugador/no_encontrado)
/// 2A. Jugador: contacta a tu admin + campo para codigo -> validar codigo
/// 2B. Admin: pregunta de seguridad + respuesta + nueva contrasena -> restablecer
/// 2C. No encontrado: mensaje generico
/// 3. Jugador con codigo validado: formulario nueva contrasena
/// 4. Admin con respuesta incorrecta + email: boton recuperar por email
/// 5. Admin con email enviado: campo para codigo -> validar codigo -> nueva contrasena
/// 6. Exito: dialog -> redirigir a login
class SolicitarRecuperacionPage extends StatelessWidget {
  const SolicitarRecuperacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RecuperacionBloc>(),
      child: const _RecuperarContrasenaView(),
    );
  }
}

class _RecuperarContrasenaView extends StatefulWidget {
  const _RecuperarContrasenaView();

  @override
  State<_RecuperarContrasenaView> createState() =>
      _RecuperarContrasenaViewState();
}

class _RecuperarContrasenaViewState extends State<_RecuperarContrasenaView> {
  // Controllers paso 1: celular
  final _celularController = TextEditingController();
  final _celularFocus = FocusNode();

  // Controllers paso 2A (jugador): codigo
  final _codigoController = TextEditingController();
  final _codigoFocus = FocusNode();

  // Controllers paso 2B (admin): respuesta pregunta + contrasena
  final _respuestaController = TextEditingController();
  final _respuestaFocus = FocusNode();

  // Controllers paso 3 / paso 2B: nueva contrasena
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmPasswordController = TextEditingController();
  final _confirmPasswordFocus = FocusNode();

  // Estado local para indicador de fuerza de contrasena
  String _currentPassword = '';

  // Error de confirmacion de contrasena
  String? _confirmPasswordError;

  @override
  void dispose() {
    _celularController.dispose();
    _codigoController.dispose();
    _respuestaController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _celularFocus.dispose();
    _codigoFocus.dispose();
    _respuestaFocus.dispose();
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
      body: BlocConsumer<RecuperacionBloc, RecuperacionState>(
        listener: (context, state) {
          if (state is RecuperacionExitosa) {
            _mostrarExitoDialog(context, state);
          } else if (state is RecuperacionBloqueada) {
            _mostrarSnackBar(
              context,
              state.mensaje,
              Icons.timer_outlined,
              Colors.orange,
            );
          } else if (state is RecuperacionError) {
            _mostrarSnackBar(
              context,
              state.mensaje,
              Icons.error_outline,
              colorScheme.error,
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
                  vertical: DesignTokens.spacingL,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(theme, colorScheme),
                      const SizedBox(height: DesignTokens.spacingXl),
                      _buildContent(context, theme, colorScheme, isMobile, state),
                      const SizedBox(height: DesignTokens.spacingL),
                      _buildLoginLink(theme, state is RecuperacionLoading),
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

  /// Header con icono de recuperacion
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
            Icons.lock_reset,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          'Recuperar contrasena',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Contenido principal segun el estado del bloc
  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    RecuperacionState state,
  ) {
    final isLoading = state is RecuperacionLoading;

    // Paso 1: Formulario de celular
    if (state is RecuperacionInitial ||
        (state is RecuperacionError && _codigoController.text.isEmpty && _respuestaController.text.isEmpty) ||
        (state is RecuperacionLoading && _celularController.text.isNotEmpty && _codigoController.text.isEmpty && _respuestaController.text.isEmpty)) {
      return _buildPaso1Celular(theme, colorScheme, isMobile, isLoading);
    }

    // Tipo identificado -> decidir paso 2
    if (state is TipoRecuperacionIdentificado) {
      switch (state.tipo) {
        case 'jugador':
          return _buildPaso2Jugador(theme, colorScheme, isMobile, state);
        case 'admin':
          return _buildPaso2Admin(theme, colorScheme, isMobile, state);
        case 'no_encontrado':
        default:
          return _buildNoEncontrado(theme, colorScheme, isMobile, state);
      }
    }

    // Codigo validado -> paso 3: formulario nueva contrasena (jugador o email)
    if (state is CodigoValidado) {
      return _buildPasoNuevaContrasenaConCodigo(
        theme, colorScheme, isMobile, isLoading, state,
      );
    }

    // Respuesta incorrecta con email -> ofrecer recuperar por email
    if (state is RespuestaIncorrectaConEmail) {
      return _buildRespuestaIncorrectaConEmail(
        theme, colorScheme, isMobile, state,
      );
    }

    // Respuesta incorrecta sin email -> mensaje final
    if (state is RespuestaIncorrectaSinEmail) {
      return _buildRespuestaIncorrectaSinEmail(
        theme, colorScheme, isMobile, state,
      );
    }

    // Email de recuperacion enviado -> campo para codigo
    if (state is EmailRecuperacionEnviado) {
      return _buildEmailEnviado(theme, colorScheme, isMobile, state);
    }

    // Cuenta bloqueada
    if (state is RecuperacionBloqueada) {
      return _buildBloqueado(theme, colorScheme, isMobile, state);
    }

    // Loading o error durante un paso avanzado
    if (state is RecuperacionLoading || state is RecuperacionError) {
      return _buildPaso1Celular(theme, colorScheme, isMobile, isLoading);
    }

    return _buildPaso1Celular(theme, colorScheme, isMobile, false);
  }

  // ========== PASO 1: CELULAR ==========

  Widget _buildPaso1Celular(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    bool isLoading,
  ) {
    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPasoIndicador(colorScheme, 1, 3),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Ingresa tu numero de celular',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Verificaremos tu cuenta para ayudarte a recuperar tu contrasena',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          AppTextField.number(
            controller: _celularController,
            focusNode: _celularFocus,
            label: 'Numero de celular',
            hint: '9XXXXXXXX',
            prefixIcon: Icons.phone_android,
            maxLength: 9,
            enabled: !isLoading,
            onSubmitted: (_) => _onIdentificarTipo(),
          ),
          const SizedBox(height: DesignTokens.spacingL),
          AppButton(
            label: 'Continuar',
            onPressed: isLoading ? null : _onIdentificarTipo,
            isLoading: isLoading,
            loadingLabel: 'Verificando...',
            isExpanded: true,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  void _onIdentificarTipo() {
    final celular = _celularController.text.trim();
    if (celular.isEmpty) {
      _mostrarSnackBar(context, 'Ingresa tu numero de celular',
          Icons.warning_amber, Colors.orange);
      return;
    }
    if (celular.length != 9 || !celular.startsWith('9')) {
      _mostrarSnackBar(context, 'El celular debe tener 9 digitos y empezar con 9',
          Icons.warning_amber, Colors.orange);
      return;
    }
    // Limpiar campos de pasos siguientes
    _codigoController.clear();
    _respuestaController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _currentPassword = '';
    _confirmPasswordError = null;

    context.read<RecuperacionBloc>().add(
          IdentificarTipoRecuperacionEvent(celular: celular),
        );
  }

  // ========== PASO 2A: JUGADOR (codigo del admin) ==========

  Widget _buildPaso2Jugador(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    TipoRecuperacionIdentificado state,
  ) {
    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPasoIndicador(colorScheme, 2, 3),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Contacta a tu administrador',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),

          // Info box
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 32,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: DesignTokens.spacingS),
                Text(
                  'Pidele a tu admin que genere un codigo de recuperacion para tu celular ${state.celular}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          Text(
            'Ingresa el codigo que te dio tu admin',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),

          AppTextField.number(
            controller: _codigoController,
            focusNode: _codigoFocus,
            label: 'Codigo de recuperacion',
            hint: '123456',
            prefixIcon: Icons.pin,
            maxLength: 6,
            enabled: true,
            onSubmitted: (_) => _onValidarCodigo(state.celular),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          AppButton(
            label: 'Validar codigo',
            onPressed: () => _onValidarCodigo(state.celular),
            isExpanded: true,
            icon: Icons.check,
          ),
          const SizedBox(height: DesignTokens.spacingM),

          _buildVolverPaso1Button(),
        ],
      ),
    );
  }

  void _onValidarCodigo(String celular) {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _mostrarSnackBar(context, 'Ingresa el codigo de recuperacion',
          Icons.warning_amber, Colors.orange);
      return;
    }
    context.read<RecuperacionBloc>().add(
          ValidarCodigoEvent(celular: celular, codigo: codigo),
        );
  }

  // ========== PASO 2B: ADMIN (pregunta de seguridad) ==========

  Widget _buildPaso2Admin(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    TipoRecuperacionIdentificado state,
  ) {
    return BlocBuilder<RecuperacionBloc, RecuperacionState>(
      builder: (context, currentState) {
        final isLoading = currentState is RecuperacionLoading;

        return AppCard(
          variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
          margin: EdgeInsets.zero,
          padding: EdgeInsets.all(
            isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPasoIndicador(colorScheme, 2, 2),
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                'Pregunta de seguridad',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacingM),

              // Pregunta de seguridad
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        state.preguntaSeguridad ?? 'Pregunta no disponible',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.spacingM),

              // Campo respuesta
              AppTextField(
                controller: _respuestaController,
                focusNode: _respuestaFocus,
                label: 'Tu respuesta',
                hint: 'Escribe tu respuesta',
                prefixIcon: Icons.edit,
                enabled: !isLoading,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: DesignTokens.spacingM),

              // Campo nueva contrasena
              AppTextField.password(
                controller: _passwordController,
                focusNode: _passwordFocus,
                label: 'Nueva contrasena',
                hint: 'Ingresa tu nueva contrasena',
                enabled: !isLoading,
                onChanged: _onPasswordChanged,
                onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
              ),
              const SizedBox(height: DesignTokens.spacingM),

              // Indicador de fuerza
              PasswordStrengthIndicator(password: _currentPassword),
              const SizedBox(height: DesignTokens.spacingM),

              // Campo confirmar contrasena
              AppTextField.password(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                label: 'Confirmar contrasena',
                hint: 'Repite tu nueva contrasena',
                errorText: _confirmPasswordError,
                enabled: !isLoading,
                onChanged: _onConfirmPasswordChanged,
                onSubmitted: (_) => _onRestablecerConPregunta(state.celular),
                showSuccessState: _confirmPasswordController.text.isNotEmpty &&
                    _passwordController.text == _confirmPasswordController.text,
              ),
              const SizedBox(height: DesignTokens.spacingXl),

              AppButton(
                label: 'Restablecer contrasena',
                onPressed: isLoading
                    ? null
                    : () => _onRestablecerConPregunta(state.celular),
                isLoading: isLoading,
                loadingLabel: 'Restableciendo...',
                isExpanded: true,
                icon: Icons.lock_reset,
              ),
              const SizedBox(height: DesignTokens.spacingM),

              _buildVolverPaso1Button(),
            ],
          ),
        );
      },
    );
  }

  void _onRestablecerConPregunta(String celular) {
    final respuesta = _respuestaController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (respuesta.isEmpty) {
      _mostrarSnackBar(context, 'Ingresa tu respuesta a la pregunta de seguridad',
          Icons.warning_amber, Colors.orange);
      return;
    }
    if (!_validarContrasenaLocal(password, confirmPassword)) return;

    context.read<RecuperacionBloc>().add(
          RestablecerConPreguntaEvent(
            celular: celular,
            respuesta: respuesta,
            nuevaContrasena: password,
            confirmarContrasena: confirmPassword,
          ),
        );
  }

  // ========== NO ENCONTRADO ==========

  Widget _buildNoEncontrado(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    TipoRecuperacionIdentificado state,
  ) {
    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off,
              size: 32,
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Celular no registrado',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            state.mensaje ??
                'No encontramos una cuenta asociada a este numero. Verifica el numero e intenta de nuevo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          AppButton(
            label: 'Intentar con otro numero',
            onPressed: _onVolver,
            variant: AppButtonVariant.primary,
            isExpanded: true,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  // ========== PASO 3: NUEVA CONTRASENA CON CODIGO ==========

  Widget _buildPasoNuevaContrasenaConCodigo(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    bool isLoading,
    CodigoValidado state,
  ) {
    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPasoIndicador(colorScheme, 3, 3),
          const SizedBox(height: DesignTokens.spacingM),

          // Info de codigo validado
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
                    'Codigo verificado correctamente',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),

          Text(
            'Establece tu nueva contrasena',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Campo nueva contrasena
          AppTextField.password(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: 'Nueva contrasena',
            hint: 'Ingresa tu nueva contrasena',
            enabled: !isLoading,
            onChanged: _onPasswordChanged,
            onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
          ),
          const SizedBox(height: DesignTokens.spacingM),

          PasswordStrengthIndicator(password: _currentPassword),
          const SizedBox(height: DesignTokens.spacingM),

          // Campo confirmar contrasena
          AppTextField.password(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            label: 'Confirmar contrasena',
            hint: 'Repite tu nueva contrasena',
            errorText: _confirmPasswordError,
            enabled: !isLoading,
            onChanged: _onConfirmPasswordChanged,
            onSubmitted: (_) => _onRestablecerConCodigo(state.celular, state.codigo),
            showSuccessState: _confirmPasswordController.text.isNotEmpty &&
                _passwordController.text == _confirmPasswordController.text,
          ),
          const SizedBox(height: DesignTokens.spacingXl),

          AppButton(
            label: 'Restablecer contrasena',
            onPressed: isLoading
                ? null
                : () => _onRestablecerConCodigo(state.celular, state.codigo),
            isLoading: isLoading,
            loadingLabel: 'Restableciendo...',
            isExpanded: true,
            icon: Icons.lock_reset,
          ),
        ],
      ),
    );
  }

  void _onRestablecerConCodigo(String celular, String codigo) {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!_validarContrasenaLocal(password, confirmPassword)) return;

    context.read<RecuperacionBloc>().add(
          RestablecerConCodigoEvent(
            celular: celular,
            codigo: codigo,
            nuevaContrasena: password,
            confirmarContrasena: confirmPassword,
          ),
        );
  }

  // ========== RESPUESTA INCORRECTA CON EMAIL ==========

  Widget _buildRespuestaIncorrectaConEmail(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    RespuestaIncorrectaConEmail state,
  ) {
    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: DesignTokens.accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber,
              size: 32,
              color: DesignTokens.accentColor,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Respuesta incorrecta',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'La respuesta a la pregunta de seguridad no es correcta.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingM),

          // Opcion de email
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(height: DesignTokens.spacingS),
                Text(
                  'Puedes recuperar tu contrasena via email de respaldo:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  state.emailMascara,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          AppButton(
            label: 'Recuperar por email',
            onPressed: () {
              context.read<RecuperacionBloc>().add(
                    SolicitarEmailRecuperacionEvent(celular: state.celular),
                  );
            },
            isExpanded: true,
            icon: Icons.email,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          _buildVolverPaso1Button(),
        ],
      ),
    );
  }

  // ========== RESPUESTA INCORRECTA SIN EMAIL ==========

  Widget _buildRespuestaIncorrectaSinEmail(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    RespuestaIncorrectaSinEmail state,
  ) {
    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 32,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'No se puede recuperar',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            state.mensaje,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          _buildVolverPaso1Button(),
        ],
      ),
    );
  }

  // ========== EMAIL ENVIADO ==========

  Widget _buildEmailEnviado(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    EmailRecuperacionEnviado state,
  ) {
    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icono de email enviado
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: DesignTokens.successColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.mark_email_read,
              size: 32,
              color: DesignTokens.successColor,
            ),
          ),
          Text(
            'Codigo enviado',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Enviamos un codigo de recuperacion a ${state.emailMascara}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Campo para codigo
          AppTextField.number(
            controller: _codigoController,
            focusNode: _codigoFocus,
            label: 'Codigo de recuperacion',
            hint: '123456',
            prefixIcon: Icons.pin,
            maxLength: 6,
            enabled: true,
            onSubmitted: (_) => _onValidarCodigo(state.celular),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          AppButton(
            label: 'Validar codigo',
            onPressed: () => _onValidarCodigo(state.celular),
            isExpanded: true,
            icon: Icons.check,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          _buildVolverPaso1Button(),
        ],
      ),
    );
  }

  // ========== BLOQUEADO ==========

  Widget _buildBloqueado(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    RecuperacionBloqueada state,
  ) {
    return AppCard(
      variant: isMobile ? AppCardVariant.standard : AppCardVariant.elevated,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(
        isMobile ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_off,
              size: 32,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Cuenta bloqueada',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            state.mensaje,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          _buildVolverPaso1Button(),
        ],
      ),
    );
  }

  // ========== HELPERS ==========

  void _onPasswordChanged(String password) {
    setState(() {
      _currentPassword = password;
      if (_confirmPasswordController.text.isNotEmpty) {
        _validatePasswordMatch();
      }
    });
  }

  void _onConfirmPasswordChanged(String confirmPassword) {
    _validatePasswordMatch();
  }

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

  /// Validacion local de contrasena antes de enviar al backend
  bool _validarContrasenaLocal(String password, String confirmPassword) {
    if (password.isEmpty) {
      _mostrarSnackBar(context, 'Ingresa tu nueva contrasena',
          Icons.warning_amber, Colors.orange);
      return false;
    }
    if (password.length < 8) {
      _mostrarSnackBar(context, 'La contrasena debe tener al menos 8 caracteres',
          Icons.warning_amber, Colors.orange);
      return false;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      _mostrarSnackBar(context, 'La contrasena debe tener al menos una mayuscula',
          Icons.warning_amber, Colors.orange);
      return false;
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      _mostrarSnackBar(context, 'La contrasena debe tener al menos una minuscula',
          Icons.warning_amber, Colors.orange);
      return false;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      _mostrarSnackBar(context, 'La contrasena debe tener al menos un numero',
          Icons.warning_amber, Colors.orange);
      return false;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      _mostrarSnackBar(context, 'La contrasena debe tener al menos un caracter especial',
          Icons.warning_amber, Colors.orange);
      return false;
    }
    if (password != confirmPassword) {
      _mostrarSnackBar(context, 'Las contrasenas no coinciden',
          Icons.warning_amber, Colors.orange);
      return false;
    }
    return true;
  }

  void _onVolver() {
    _celularController.clear();
    _codigoController.clear();
    _respuestaController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _currentPassword = '';
      _confirmPasswordError = null;
    });
    context.read<RecuperacionBloc>().add(const RecuperacionResetEvent());
  }

  Widget _buildVolverPaso1Button() {
    return TextButton.icon(
      onPressed: _onVolver,
      icon: const Icon(Icons.arrow_back, size: 16),
      label: const Text('Cambiar celular'),
    );
  }

  /// Indicador visual de paso (e.g. paso 1 de 3)
  Widget _buildPasoIndicador(ColorScheme colorScheme, int paso, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total * 2 - 1, (index) {
        if (index.isOdd) {
          // Conector entre dots
          final pasoActual = (index + 1) ~/ 2;
          return Container(
            width: 30,
            height: 2,
            color: paso > pasoActual
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          );
        } else {
          // Dot
          final pasoIndex = index ~/ 2 + 1;
          return Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: paso >= pasoIndex
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          );
        }
      }),
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

  /// Dialog de exito al restablecer contrasena
  void _mostrarExitoDialog(
    BuildContext context,
    RecuperacionExitosa state,
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

                  Text(
                    'Contrasena actualizada',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spacingS),

                  Text(
                    state.mensaje,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Indicador de sesiones cerradas
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

  /// Muestra SnackBar generico
  void _mostrarSnackBar(
    BuildContext context,
    String mensaje,
    IconData icon,
    Color backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(color: Colors.white),
              ),
            ),
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

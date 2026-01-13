import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/design_tokens.dart';
import '../theme/app_colors.dart';

/// Campo de texto personalizado con soporte para validacion y estados
class AppTextField extends StatefulWidget {
  /// Constructor principal
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.initialValue,
    this.autovalidateMode,
    this.showSuccessState = false,
  });

  /// Constructor para email
  const AppTextField.email({
    super.key,
    this.controller,
    this.focusNode,
    this.label = 'Correo electronico',
    this.hint = 'ejemplo@correo.com',
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.initialValue,
    this.autovalidateMode,
    this.showSuccessState = false,
  })  : prefixIcon = Icons.email_outlined,
        suffixIcon = null,
        onSuffixTap = null,
        obscureText = false,
        maxLines = 1,
        minLines = null,
        maxLength = null,
        keyboardType = TextInputType.emailAddress,
        textInputAction = TextInputAction.next,
        textCapitalization = TextCapitalization.none,
        inputFormatters = null,
        onTap = null;

  /// Constructor para password
  factory AppTextField.password({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String label = 'Contrasena',
    String? hint,
    String? helperText,
    String? errorText,
    bool enabled = true,
    bool autofocus = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    String? initialValue,
    AutovalidateMode? autovalidateMode,
    bool showSuccessState = false,
  }) {
    return _PasswordTextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      label: label,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      enabled: enabled,
      autofocus: autofocus,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      initialValue: initialValue,
      autovalidateMode: autovalidateMode,
      showSuccessState: showSuccessState,
    );
  }

  /// Constructor para busqueda
  const AppTextField.search({
    super.key,
    this.controller,
    this.focusNode,
    this.hint = 'Buscar...',
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  })  : label = null,
        helperText = null,
        errorText = null,
        prefixIcon = Icons.search,
        suffixIcon = Icons.clear,
        onSuffixTap = null,
        obscureText = false,
        readOnly = false,
        maxLines = 1,
        minLines = null,
        maxLength = null,
        keyboardType = TextInputType.text,
        textInputAction = TextInputAction.search,
        textCapitalization = TextCapitalization.none,
        inputFormatters = null,
        validator = null,
        onTap = null,
        initialValue = null,
        autovalidateMode = null,
        showSuccessState = false;

  /// Constructor para numero
  AppTextField.number({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.initialValue,
    this.autovalidateMode,
    this.showSuccessState = false,
  })  : obscureText = false,
        maxLines = 1,
        minLines = null,
        keyboardType = TextInputType.number,
        textInputAction = TextInputAction.next,
        textCapitalization = TextCapitalization.none,
        inputFormatters = [FilteringTextInputFormatter.digitsOnly],
        onTap = null;

  /// Constructor para textarea
  const AppTextField.multiline({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 4,
    this.minLines = 3,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.initialValue,
    this.autovalidateMode,
    this.showSuccessState = false,
  })  : prefixIcon = null,
        suffixIcon = null,
        onSuffixTap = null,
        obscureText = false,
        keyboardType = TextInputType.multiline,
        textInputAction = TextInputAction.newline,
        textCapitalization = TextCapitalization.sentences,
        inputFormatters = null,
        onTap = null;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final String? initialValue;
  final AutovalidateMode? autovalidateMode;
  final bool showSuccessState;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;
    final showSuccess = widget.showSuccessState && !hasError;

    Color? suffixColor;
    if (hasError) {
      suffixColor = colorScheme.error;
    } else if (showSuccess) {
      suffixColor = AppColors.victoria;
    }

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      initialValue: widget.initialValue,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      autovalidateMode: widget.autovalidateMode,
      style: TextStyle(
        color: widget.enabled
            ? colorScheme.onSurface
            : colorScheme.onSurface.withValues(alpha: DesignTokens.opacityDisabled),
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: _isFocused && !hasError
                    ? colorScheme.primary
                    : hasError
                        ? colorScheme.error
                        : null,
              )
            : null,
        suffixIcon: _buildSuffixIcon(colorScheme, hasError, showSuccess, suffixColor),
        border: showSuccess
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                borderSide: BorderSide(color: AppColors.victoria),
              )
            : null,
        enabledBorder: showSuccess
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                borderSide: BorderSide(color: AppColors.victoria),
              )
            : null,
        focusedBorder: showSuccess
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                borderSide: BorderSide(color: AppColors.victoria, width: 2),
              )
            : null,
      ),
    );
  }

  Widget? _buildSuffixIcon(
    ColorScheme colorScheme,
    bool hasError,
    bool showSuccess,
    Color? suffixColor,
  ) {
    if (showSuccess) {
      return Icon(Icons.check_circle, color: AppColors.victoria);
    }

    if (widget.suffixIcon == null) return null;

    if (widget.onSuffixTap != null) {
      return IconButton(
        icon: Icon(widget.suffixIcon, color: suffixColor),
        onPressed: widget.onSuffixTap,
      );
    }

    return Icon(widget.suffixIcon, color: suffixColor);
  }
}

/// Campo de password con toggle de visibilidad
class _PasswordTextField extends AppTextField {
  const _PasswordTextField({
    super.key,
    super.controller,
    super.focusNode,
    super.label,
    super.hint,
    super.helperText,
    super.errorText,
    super.enabled,
    super.autofocus,
    super.validator,
    super.onChanged,
    super.onSubmitted,
    super.initialValue,
    super.autovalidateMode,
    super.showSuccessState,
  }) : super(
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
        );

  @override
  State<AppTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends _AppTextFieldState {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;
    final showSuccess = widget.showSuccessState && !hasError;

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      initialValue: widget.initialValue,
      obscureText: _obscureText,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      autovalidateMode: widget.autovalidateMode,
      style: TextStyle(
        color: widget.enabled
            ? colorScheme.onSurface
            : colorScheme.onSurface.withValues(alpha: DesignTokens.opacityDisabled),
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixIcon: Icon(
          Icons.lock_outline,
          color: _isFocused && !hasError
              ? colorScheme.primary
              : hasError
                  ? colorScheme.error
                  : null,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: hasError
                ? colorScheme.error
                : showSuccess
                    ? AppColors.victoria
                    : null,
          ),
          onPressed: _toggleVisibility,
        ),
        border: showSuccess
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                borderSide: BorderSide(color: AppColors.victoria),
              )
            : null,
        enabledBorder: showSuccess
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                borderSide: BorderSide(color: AppColors.victoria),
              )
            : null,
        focusedBorder: showSuccess
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                borderSide: BorderSide(color: AppColors.victoria, width: 2),
              )
            : null,
      ),
    );
  }
}

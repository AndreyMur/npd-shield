import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';

InputDecoration _decoration(
  BuildContext context, {
  String? label,
  String? hint,
  String? helper,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool dense = false,
}) {
  final tokens = AppTokens.of(context);
  OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: AppRadius.fieldRadius,
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    isDense: dense,
    filled: true,
    fillColor: tokens.surfaceVariant,
    border: border(tokens.border),
    enabledBorder: border(tokens.border),
    focusedBorder: border(tokens.primary, width: 1.5),
    errorBorder: border(tokens.destructive),
    focusedErrorBorder: border(tokens.destructive, width: 1.5),
    disabledBorder: border(tokens.border.withValues(alpha: 0.5)),
  );
}

/// Текстовое поле дизайн-системы (без валидации формы).
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool dense;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.dense = false,
    this.keyboardType,
    this.minLines,
    this.maxLines,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: _decoration(
        context,
        label: label,
        hint: hint,
        helper: helper,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        dense: dense,
      ),
    );
  }
}

/// Текстовое поле дизайн-системы с валидацией внутри [Form].
///
/// Ключ, переданный в конструктор, ставится на внутренний [TextFormField],
/// чтобы существующие тесты могли адресовать поле как `TextFormField`.
class AppTextFormField extends StatelessWidget {
  /// Ключ внутреннего [TextFormField].
  final Key? fieldKey;

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  /// Форматтеры ввода (ограничение допустимых символов).
  final List<TextInputFormatter>? inputFormatters;

  /// Действие клавиатуры (next/done/newline).
  final TextInputAction? textInputAction;

  /// Вызывается при отправке поля с клавиатуры.
  final ValueChanged<String>? onFieldSubmitted;

  /// Автофокус при открытии экрана.
  final bool autofocus;

  const AppTextFormField({
    Key? key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.minLines,
    this.maxLines,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.validator,
    this.inputFormatters,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofocus = false,
  }) : fieldKey = key,
       super(key: null);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      decoration: _decoration(
        context,
        label: label,
        hint: hint,
        helper: helper,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Standard text input — height 48–52px, radius 12, focus glow.
class MCInput extends StatefulWidget {
  const MCInput({
    required this.controller,
    this.hint,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.focusColor,
    super.key,
  });

  final TextEditingController controller;
  final String? hint;
  final String? label;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final Color? focusColor;

  @override
  State<MCInput> createState() => _MCInputState();
}

class _MCInputState extends State<MCInput> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fColor = widget.focusColor ?? MCColors.primary;
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      autofocus: widget.autofocus,
      style: MCTypography.body,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hint,
        labelText: widget.label,
        hintStyle: MCTypography.body.copyWith(color: MCColors.textMuted),
        labelStyle: MCTypography.label.copyWith(color: MCColors.textSecondary),
        filled: true,
        fillColor: widget.enabled
            ? (_focused ? MCColors.card : MCColors.inputBg)
            : MCColors.borderLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                size: 18,
                color: _focused ? fColor : MCColors.textMuted,
              )
            : null,
        suffixIcon: widget.suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
          borderSide: const BorderSide(color: MCColors.border, width: MCSpacing.borderMed),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
          borderSide: const BorderSide(color: MCColors.border, width: MCSpacing.borderMed),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
          borderSide: BorderSide(color: fColor, width: MCSpacing.borderMed),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MCSpacing.radiusInput),
          borderSide: const BorderSide(color: MCColors.borderLight, width: MCSpacing.borderThin),
        ),
      ),
    );
  }
}

/// Six individual OTP boxes.
class MCOtpInput extends StatefulWidget {
  const MCOtpInput({
    required this.onCompleted,
    this.length = 6,
    super.key,
  });

  final ValueChanged<String> onCompleted;
  final int length;

  @override
  State<MCOtpInput> createState() => _MCOtpInputState();
}

class _MCOtpInputState extends State<MCOtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes  = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int i, String val) {
    if (val.length > 1) {
      _controllers[i].text = val[val.length - 1];
    }
    if (val.isNotEmpty && i < widget.length - 1) {
      _focusNodes[i + 1].requestFocus();
    }
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == widget.length) widget.onCompleted(otp);
  }

  void _onKey(int i, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey.keyLabel == 'Backspace' &&
        _controllers[i].text.isEmpty &&
        i > 0) {
      _focusNodes[i - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (e) => _onKey(i, e),
          child: SizedBox(
            width: 48,
            height: 56,
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: MCTypography.h2.copyWith(
                color: MCColors.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: _controllers[i].text.isNotEmpty
                    ? const Color(0xFFF5F8FF)
                    : MCColors.inputBg,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MCSpacing.radiusOtpBox),
                  borderSide: const BorderSide(color: MCColors.border, width: MCSpacing.borderMed),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MCSpacing.radiusOtpBox),
                  borderSide: const BorderSide(color: MCColors.border, width: MCSpacing.borderMed),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MCSpacing.radiusOtpBox),
                  borderSide: const BorderSide(color: MCColors.primary, width: 2),
                ),
              ),
              onChanged: (v) => _onChanged(i, v),
            ),
          ),
        );
      }),
    );
  }
}

/// Borderless textarea (composer style).
class MCTextarea extends StatelessWidget {
  const MCTextarea({
    required this.controller,
    this.hint,
    this.style,
    this.maxLines,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final String? hint;
  final TextStyle? style;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: style ?? MCTypography.bodyLg,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: (style ?? MCTypography.bodyLg).copyWith(color: MCColors.textMuted),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safira/core/constants/app_constants.dart';

/// A highly customizable, accessible text field for Safira.
///
/// Features:
/// - Password visibility toggle
/// - Strength indicator (for password fields)
/// - Copy button
/// - Clear button
/// - Error state with animated shake
/// - Accessibility labels
class SafiraTextField extends StatefulWidget {
  const SafiraTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.showStrengthIndicator = false,
    this.showCopyButton = false,
    this.showClearButton = false,
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onCopied,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final bool showStrengthIndicator;
  final bool showCopyButton;
  final bool showClearButton;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final VoidCallback? onCopied;

  @override
  State<SafiraTextField> createState() => _SafiraTextFieldState();
}

class _SafiraTextFieldState extends State<SafiraTextField>
    with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  String _currentValue = '';
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _currentValue = widget.controller?.text ?? '';
    widget.controller?.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    setState(() => _currentValue = widget.controller?.text ?? '');
  }

  @override
  void didUpdateWidget(SafiraTextField old) {
    super.didUpdateWidget(old);
    // Trigger shake animation when error appears
    if (old.errorText == null && widget.errorText != null) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeOffset(_shakeAnimation.value), 0),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.isPassword && _obscureText,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            readOnly: widget.readOnly,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            onChanged: (v) {
              setState(() => _currentValue = v);
              widget.onChanged?.call(v);
            },
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              helperText: widget.helperText,
              errorText: widget.errorText,
              prefixIcon: widget.prefixIcon,
              suffixIcon: _buildSuffix(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UiConstants.radiusMedium),
              ),
              filled: true,
            ),
          ),
          if (widget.showStrengthIndicator && widget.isPassword && _currentValue.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _PasswordStrengthBar(password: _currentValue),
            ),
        ],
      ),
    );
  }

  Widget? _buildSuffix(BuildContext context) {
    final buttons = <Widget>[];

    if (widget.showCopyButton && _currentValue.isNotEmpty) {
      buttons.add(
        Tooltip(
          message: 'Copy',
          child: IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _currentValue));
              widget.onCopied?.call();
            },
            iconSize: 20,
          ),
        ),
      );
    }

    if (widget.showClearButton && _currentValue.isNotEmpty && !widget.readOnly) {
      buttons.add(
        Tooltip(
          message: 'Clear',
          child: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              widget.controller?.clear();
              setState(() => _currentValue = '');
              widget.onChanged?.call('');
            },
            iconSize: 20,
          ),
        ),
      );
    }

    if (widget.isPassword) {
      buttons.add(
        Tooltip(
          message: _obscureText ? 'Show password' : 'Hide password',
          child: IconButton(
            icon: Icon(_obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscureText = !_obscureText),
            iconSize: 20,
          ),
        ),
      );
    }

    if (buttons.isEmpty) return widget.suffixIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: buttons,
    );
  }

  double _shakeOffset(double value) {
    // Sine wave shake effect
    const amplitude = 8.0;
    return amplitude * (value < 0.5 ? value * 2 : (1 - value) * 2) *
        (value * 4 % 2 < 1 ? 1 : -1);
  }
}

/// Animated password strength indicator bar.
class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final score = _getScore();
    final color = _getColor(context, score);
    final label = _getLabel(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score + 1) / 5,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
            ),
            Text(
              '${_entropy().toStringAsFixed(0)} bits entropy',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  int _getScore() {
    if (password.length < 8) return 0;
    var score = 0;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;
    if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    return score.clamp(0, 4);
  }

  Color _getColor(BuildContext context, int score) => switch (score) {
        0 => Colors.red.shade700,
        1 => Colors.orange.shade700,
        2 => Colors.amber.shade700,
        3 => Colors.lightGreen.shade700,
        _ => Colors.green.shade700,
      };

  String _getLabel(int score) => switch (score) {
        0 => 'Very Weak',
        1 => 'Weak',
        2 => 'Fair',
        3 => 'Strong',
        _ => 'Very Strong',
      };

  double _entropy() {
    if (password.isEmpty) return 0;
    var charsetSize = 0;
    if (password.contains(RegExp(r'[a-z]'))) charsetSize += 26;
    if (password.contains(RegExp(r'[A-Z]'))) charsetSize += 26;
    if (password.contains(RegExp(r'[0-9]'))) charsetSize += 10;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) charsetSize += 32;
    if (charsetSize == 0) return 0;
    return password.length * (charsetSize.toDouble().logBase2());
  }
}

extension on double {
  double logBase2() => this <= 0 ? 0 : (log(this) / log(2));
}

double log(num x) => x <= 0 ? double.negativeInfinity : 2.302585092994046 * _log10(x);
double _log10(num x) => x <= 0 ? double.negativeInfinity : _log(x) / 2.302585092994046;
double _log(num x) {
  if (x <= 0) return double.negativeInfinity;
  var result = 0.0;
  var n = x.toDouble();
  while (n >= 2.718281828459045) {
    n /= 2.718281828459045;
    result += 1;
  }
  result += (n - 1) - (n - 1) * (n - 1) / 2;
  return result;
}

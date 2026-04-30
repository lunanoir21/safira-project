import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:safira/core/constants/app_constants.dart';

/// A fully animated, accessible primary button for Safira.
///
/// Features:
/// - Loading state with spinner
/// - Haptic feedback
/// - Scale press animation
/// - Disabled state
/// - Full-width or compact variants
class SafiraButton extends StatefulWidget {
  const SafiraButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDestructive = false,
    this.isFullWidth = true,
    this.variant = SafiraButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDestructive;
  final bool isFullWidth;
  final SafiraButtonVariant variant;

  @override
  State<SafiraButton> createState() => _SafiraButtonState();
}

class _SafiraButtonState extends State<SafiraButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Widget button = switch (widget.variant) {
      SafiraButtonVariant.filled => FilledButton(
          onPressed: isEnabled ? _handlePress : null,
          style: FilledButton.styleFrom(
            minimumSize: widget.isFullWidth
                ? const Size(double.infinity, 52)
                : const Size(0, 52),
            backgroundColor: widget.isDestructive ? colorScheme.error : null,
            foregroundColor: widget.isDestructive ? colorScheme.onError : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UiConstants.radiusMedium),
            ),
          ),
          child: _buildChild(),
        ),
      SafiraButtonVariant.outlined => OutlinedButton(
          onPressed: isEnabled ? _handlePress : null,
          style: OutlinedButton.styleFrom(
            minimumSize: widget.isFullWidth
                ? const Size(double.infinity, 52)
                : const Size(0, 52),
            foregroundColor: widget.isDestructive ? colorScheme.error : null,
            side: BorderSide(
              color: widget.isDestructive
                  ? colorScheme.error
                  : colorScheme.outline,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UiConstants.radiusMedium),
            ),
          ),
          child: _buildChild(),
        ),
      SafiraButtonVariant.text => TextButton(
          onPressed: isEnabled ? _handlePress : null,
          style: TextButton.styleFrom(
            minimumSize: widget.isFullWidth
                ? const Size(double.infinity, 52)
                : const Size(0, 52),
            foregroundColor: widget.isDestructive ? colorScheme.error : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UiConstants.radiusMedium),
            ),
          ),
          child: _buildChild(),
        ),
    };

    return ScaleTransition(
      scale: _scaleAnimation,
      child: button,
    );
  }

  Widget _buildChild() {
    if (widget.isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 20),
          const SizedBox(width: 8),
          Text(widget.label),
        ],
      );
    }

    return Text(widget.label);
  }

  void _handlePress() {
    _pressController.forward().then((_) => _pressController.reverse());
    widget.onPressed?.call();
  }
}

enum SafiraButtonVariant { filled, outlined, text }

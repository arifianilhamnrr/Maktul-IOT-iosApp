import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Tombol Neobrutalism dengan feedback mekanik fisik:
/// saat ditekan, tombol bergeser masuk menyerap bayangannya (tactile press) disertai haptic.
class NeoButton extends StatefulWidget {
  const NeoButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = NeoColors.card,
    this.foregroundColor = NeoColors.ink,
    this.shadowOffset = 3.5,
    this.borderRadius = NeoBox.radiusPill,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color foregroundColor;
  final double shadowOffset;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  void _handleTapDown(_) {
    if (widget.onPressed == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(_) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final offset = _isPressed ? widget.shadowOffset : 0.0;
    final currentShadow = _isPressed ? 0.0 : widget.shadowOffset;

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? _handleTapDown : null,
        onTapUp: enabled ? _handleTapUp : null,
        onTapCancel: enabled ? _handleTapCancel : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: Matrix4.translationValues(offset, offset, 0),
          decoration: BoxDecoration(
            color: enabled ? widget.backgroundColor : NeoColors.muted,
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: NeoColors.ink,
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: NeoColors.ink,
                offset: Offset(currentShadow, currentShadow),
                blurRadius: 0,
              ),
            ],
          ),
          padding: widget.padding,
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: NeoText.display,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.6,
              color: enabled ? widget.foregroundColor : NeoColors.textMuted,
            ),
            child: IconTheme(
              data: IconThemeData(
                color: enabled ? widget.foregroundColor : NeoColors.textMuted,
                size: 18,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

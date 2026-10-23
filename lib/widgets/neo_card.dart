import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Kartu Neobrutalism: border hitam tebal + bayangan keras (hard offset shadow, 0 blur).
/// Jika [onTap] disediakan, kartu memiliki feedback tekan mekanik (tactile press) dan haptic.
class NeoCard extends StatefulWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor = NeoColors.card,
    this.borderColor = NeoColors.ink,
    this.borderWidth = NeoBox.borderWidth,
    this.shadowOffset = NeoBox.shadowOffset,
    this.borderRadius = NeoBox.radius,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double shadowOffset;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  State<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends State<NeoCard> {
  bool _isPressed = false;

  void _handleTapDown(_) {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(_) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final offset = (_isPressed && interactive) ? widget.shadowOffset : 0.0;
    final currentShadow = (_isPressed && interactive) ? 0.0 : widget.shadowOffset;

    Widget cardWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeInOut,
      transform: Matrix4.translationValues(offset, offset, 0),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
        border: Border.all(color: widget.borderColor, width: widget.borderWidth),
        boxShadow: [
          BoxShadow(
            color: widget.borderColor,
            offset: Offset(currentShadow, currentShadow),
            blurRadius: 0,
          ),
        ],
      ),
      padding: widget.padding,
      child: widget.child,
    );

    if (interactive) {
      cardWidget = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: cardWidget,
      );
    }

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: cardWidget,
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kartu kaca (glassmorphism): blur latar + border tipis + isi semi transparan.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.xl),
    this.tint,
    this.borderColor,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppSpace.radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (tint ?? AppColors.card).withValues(alpha: 0.55),
              borderRadius: AppSpace.radius,
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

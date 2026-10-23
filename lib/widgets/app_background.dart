import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Latar bertingkat: gradien gelap + dua sorot warna.
/// Sorot ini yang membuat efek kaca pada [GlassCard] terlihat.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, AppColors.backgroundAlt],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _Sorot(
                warna: AppColors.accent.withValues(alpha: 0.20),
                ukuran: 320,
              ),
            ),
            Positioned(
              bottom: -140,
              left: -110,
              child: _Sorot(
                warna: AppColors.info.withValues(alpha: 0.16),
                ukuran: 360,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sorot extends StatelessWidget {
  const _Sorot({required this.warna, required this.ukuran});

  final Color warna;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: ukuran,
          height: ukuran,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [warna, warna.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

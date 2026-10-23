import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Angka besar dengan transisi halus saat nilai berubah.
/// Animasi dimatikan otomatis bila pengguna memakai Reduced Motion.
class MetricValue extends StatelessWidget {
  const MetricValue({
    super.key,
    required this.nilai,
    required this.satuan,
    required this.semantik,
    this.gaya,
    this.gayaSatuan,
  });

  final String nilai;
  final String satuan;
  final String semantik;
  final TextStyle? gaya;
  final TextStyle? gayaSatuan;

  @override
  Widget build(BuildContext context) {
    final kurangiGerak = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final teks = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: nilai),
          TextSpan(text: ' $satuan', style: gayaSatuan ?? AppText.monoKecil),
        ],
      ),
      style: gaya ?? AppText.angka,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Semantics(
      label: semantik,
      child: kurangiGerak
          ? teks
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final geser = Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: geser, child: child),
                );
              },
              child: KeyedSubtree(key: ValueKey(nilai), child: teks),
            ),
    );
  }
}

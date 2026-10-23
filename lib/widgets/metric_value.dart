import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Angka besar Neobrutalism dengan transisi halus saat nilai berubah.
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
          TextSpan(
            text: ' $satuan',
            style: gayaSatuan ??
                const TextStyle(
                  fontFamily: NeoText.mono,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: NeoColors.ink,
                ),
          ),
        ],
      ),
      style: gaya ?? NeoText.angkaBesar,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Semantics(
      label: semantik,
      child: kurangiGerak
          ? teks
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutQuad,
              switchOutCurve: Curves.easeInQuad,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: KeyedSubtree(key: ValueKey(nilai), child: teks),
            ),
    );
  }
}

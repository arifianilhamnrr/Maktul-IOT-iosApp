import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum LiveStatus { live, stale, paused, waiting }

extension LiveStatusStyle on LiveStatus {
  String get label {
    switch (this) {
      case LiveStatus.live:
        return 'LIVE';
      case LiveStatus.stale:
        return 'TERTUNDA';
      case LiveStatus.paused:
        return 'DIJEDA';
      case LiveStatus.waiting:
        return 'MENUNGGU';
    }
  }

  Color get color {
    switch (this) {
      case LiveStatus.live:
        return NeoColors.lime;
      case LiveStatus.stale:
        return NeoColors.yellow;
      case LiveStatus.paused:
        return NeoColors.muted;
      case LiveStatus.waiting:
        return NeoColors.cyan;
    }
  }

  bool get berdenyut => this == LiveStatus.live;
}

/// Badge status data gaya Neobrutalism: border hitam tebal, bayangan keras 2px, warna pop.
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key, required this.status});

  final LiveStatus status;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sinkronAnimasi();
  }

  @override
  void didUpdateWidget(covariant LiveBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _sinkronAnimasi();
  }

  void _sinkronAnimasi() {
    final kurangiGerak = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (widget.status.berdenyut && !kurangiGerak) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warna = widget.status.color;

    return Semantics(
      label: 'Status data: ${widget.status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: warna,
          borderRadius: NeoBox.radiusPill,
          border: Border.all(color: NeoColors.ink, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: NeoColors.ink,
              offset: Offset(2.5, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.25, end: 1.0).animate(_controller),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: NeoColors.ink,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.status.label,
              style: const TextStyle(
                fontFamily: NeoText.display,
                fontSize: 12,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w800,
                color: NeoColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label status perangkat (Menyala / Mati) gaya Neobrutalism.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.menyala});

  final bool menyala;

  @override
  Widget build(BuildContext context) {
    final warna = menyala ? NeoColors.lime : NeoColors.muted;

    return Semantics(
      label: menyala ? 'Status: menyala' : 'Status: mati',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: warna,
          borderRadius: NeoBox.radiusPill,
          border: Border.all(color: NeoColors.ink, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: NeoColors.ink,
              offset: Offset(2.0, 2.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: NeoColors.ink,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              menyala ? 'MENYALA' : 'MATI',
              style: const TextStyle(
                fontFamily: NeoText.display,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: NeoColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

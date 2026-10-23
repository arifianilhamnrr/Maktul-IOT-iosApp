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
        return AppColors.accent;
      case LiveStatus.stale:
        return AppColors.warning;
      case LiveStatus.paused:
        return AppColors.mutedForeground;
      case LiveStatus.waiting:
        return AppColors.info;
    }
  }

  bool get berdenyut => this == LiveStatus.live;
}

/// Badge status data: hanya berlabel LIVE kalau memang ada pembaruan terbaru.
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
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.12),
          borderRadius: AppSpace.radiusPill,
          border: Border.all(color: warna.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.status.label,
              style: TextStyle(
                fontFamily: AppText.body,
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: warna,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label status perangkat (Menyala / Mati).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.menyala});

  final bool menyala;

  @override
  Widget build(BuildContext context) {
    final warna = menyala ? AppColors.accent : AppColors.mutedForeground;

    return Semantics(
      label: menyala ? 'Status: menyala' : 'Status: mati',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.12),
          borderRadius: AppSpace.radiusPill,
          border: Border.all(color: warna.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              menyala ? 'Menyala' : 'Mati',
              style: TextStyle(
                fontFamily: AppText.body,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: warna,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Menampilkan toast / snackbar bergaya Neobrutalism kustom
void showNeoToast(
  BuildContext context, {
  required String message,
  IconData icon = Icons.info_outline_rounded,
  Color backgroundColor = NeoColors.yellow,
  Color iconColor = NeoColors.ink,
}) {
  final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
  if (scaffoldMessenger == null) return;

  scaffoldMessenger.hideCurrentSnackBar();
  scaffoldMessenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      duration: const Duration(seconds: 3),
      content: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: NeoBox.radiusSmall,
          border: Border.all(color: NeoColors.ink, width: 2.2),
          boxShadow: const [
            BoxShadow(
              color: NeoColors.ink,
              offset: Offset(3.5, 3.5),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: NeoColors.ink, width: 1.8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: NeoText.display,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: NeoColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

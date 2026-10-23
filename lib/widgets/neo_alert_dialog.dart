import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'neo_button.dart';

/// Pop-up dialog notifikasi suhu panas (Tugas Pengayaan d Labsheet 2)
Future<void> showNeoHeatAlert(
  BuildContext context, {
  required String deviceId,
  required double suhu,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2), // soft red/coral
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NeoColors.ink, width: 2.8),
            boxShadow: const [
              BoxShadow(
                color: NeoColors.ink,
                offset: Offset(5, 5),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: NeoColors.coral,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NeoColors.ink, width: 2.2),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoColors.ink,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'PERINGATAN SUHU TINGGI!',
                      style: TextStyle(
                        fontFamily: NeoText.display,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: NeoColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NeoColors.ink, width: 2.0),
                ),
                child: Text(
                  'Suhu terdeteksi: ${suhu.toStringAsFixed(1)} °C\nDevice: $deviceId',
                  style: const TextStyle(
                    fontFamily: NeoText.mono,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NeoColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Suhu ruangan melampaui batas optimal (di atas 30.0°C). Segera periksa ventilasi atau aktifkan pendingin ruangan.',
                style: TextStyle(
                  fontFamily: NeoText.body,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: NeoColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: NeoButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  backgroundColor: NeoColors.coral,
                  foregroundColor: Colors.white,
                  child: const Text('MENGERTI'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

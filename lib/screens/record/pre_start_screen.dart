import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../../tracker/session_controller.dart';
import '../../widgets/core/gps_status_indicator.dart';
import '../../widgets/core/trego_app_bar.dart';
import '../../widgets/core/trego_scaffold.dart';

class PreStartScreen extends StatelessWidget {
  const PreStartScreen({super.key});

  static GpsStatus _statusFor(double? accuracyMeters) {
    if (accuracyMeters == null) return GpsStatus.acquiring;
    if (accuracyMeters > 30) return GpsStatus.weak;
    return GpsStatus.ready;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SessionController>();
    final tokens = context.tokens;
    final accuracyMeters = controller.currentAccuracyMeters;
    final status = _statusFor(accuracyMeters);
    final canStart = status != GpsStatus.acquiring;

    return TregoScaffold(
      appBar: TregoAppBar(
        title: 'Ready',
        trailing: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: () => controller.cancelFlow(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.md, vertical: Space.sm),
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border.all(color: tokens.border),
                borderRadius: BorderRadius.circular(Radii.compactCard),
              ),
              child: Row(children: [
                const Text('🏃', style: TextStyle(fontSize: 22)),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text('Running', style: context.typo.titleSmall),
                ),
                Icon(Icons.chevron_right, color: tokens.inkMuted),
              ]),
            ),
            const SizedBox(height: Space.md),
            Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border.all(color: tokens.border),
                borderRadius: BorderRadius.circular(Radii.compactCard),
              ),
              child: Row(children: [
                GpsStatusIndicator(
                  status: status,
                  accuracyMeters: accuracyMeters,
                ),
              ]),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: canStart ? () => controller.startCountdown() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.brand,
                foregroundColor: tokens.onBrand,
                disabledBackgroundColor: tokens.surface,
                disabledForegroundColor: tokens.inkMuted,
                padding: const EdgeInsets.symmetric(vertical: Space.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.standardCard),
                ),
                elevation: 0,
              ),
              child: Text('START RUN', style: context.typo.button),
            ),
            const SizedBox(height: Space.sm),
            Center(
              child: Text(
                'Screen stays on while recording',
                style: context.typo.bodySmall.copyWith(color: tokens.inkFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../../tracker/session_controller.dart';

class StopConfirmScreen extends StatelessWidget {
  const StopConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SessionController>();
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Space.lg),
              Text('Paused · Tap to choose',
                  textAlign: TextAlign.center,
                  style: context.typo.label.copyWith(color: tokens.inkMuted)),
              const SizedBox(height: Space.sm),
              Text('Finish your run?',
                  textAlign: TextAlign.center,
                  style: context.typo.title),
              const SizedBox(height: Space.lg),
              Container(
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  border: Border.all(color: tokens.border),
                  borderRadius: BorderRadius.circular(Radii.standardCard),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Mini(value: _fmtDuration(c.elapsed), label: 'Time'),
                    _Mini(value: c.distanceKm.toStringAsFixed(2), label: 'km'),
                    _Mini(
                      value: c.currentPacePerKm == null
                          ? '—'
                          : _fmtDuration(c.currentPacePerKm!),
                      label: '/km',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _Btn(
                label: '▶ RESUME RUN',
                onPressed: c.resume,
                bg: tokens.success,
                fg: tokens.onSuccess,
              ),
              const SizedBox(height: Space.sm),
              _Btn(
                label: '✓ FINISH & SAVE',
                onPressed: () => c.finish(),
                bg: tokens.brand,
                fg: tokens.onBrand,
              ),
              const SizedBox(height: Space.sm),
              TextButton(
                onPressed: () => _confirmDiscard(context, c),
                child: Text(
                  'Discard run',
                  style: context.typo.button.copyWith(color: tokens.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context, SessionController c) async {
    final tokens = context.tokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface,
        title: Text('Discard this run?', style: context.typo.titleSmall),
        content: Text(
          "You'll lose everything you've recorded.",
          style: context.typo.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: tokens.danger),
            child: const Text('DISCARD'),
          ),
        ],
      ),
    );
    if (confirmed == true) c.discard();
  }

  static String _fmtDuration(Duration d) {
    final mm = d.inMinutes;
    final ss = d.inSeconds % 60;
    return '${mm.toString()}:${ss.toString().padLeft(2, '0')}';
  }
}

class _Mini extends StatelessWidget {
  final String value;
  final String label;
  const _Mini({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: context.typo.stat.copyWith(fontSize: 22)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(),
            style: context.typo.label.copyWith(color: tokens.inkMuted)),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color bg, fg;
  const _Btn({
    required this.label,
    required this.onPressed,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(Radii.standardCard),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.standardCard),
        ),
        padding: const EdgeInsets.symmetric(vertical: Space.lg),
        alignment: Alignment.center,
        child: Text(label, style: context.typo.button.copyWith(color: fg)),
      ),
    );
  }
}

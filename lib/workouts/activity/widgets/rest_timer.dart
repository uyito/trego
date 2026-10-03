import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/theme/context_tokens.dart';

/// Countdown rest timer (mm:ss) with a Skip button. Fires [onDone] exactly
/// once, either when the countdown reaches zero or when Skip is tapped.
class RestTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback? onDone;

  const RestTimer({super.key, required this.seconds, this.onDone});

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  late int _remaining;
  Timer? _timer;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    if (_remaining <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  void _tick(Timer t) {
    if (!mounted) return;
    setState(() => _remaining--);
    if (_remaining <= 0) _finish();
  }

  void _finish() {
    _timer?.cancel();
    if (_fired) return;
    _fired = true;
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int s) {
    final v = s < 0 ? 0 : s;
    final m = (v ~/ 60).toString().padLeft(2, '0');
    final sec = (v % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_fmt(_remaining), style: typo.stat.copyWith(color: tokens.brand)),
        const SizedBox(width: 16),
        TextButton(
          onPressed: _finish,
          child: Text('Skip', style: typo.button.copyWith(color: tokens.ink)),
        ),
      ],
    );
  }
}

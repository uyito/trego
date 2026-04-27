import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/context_tokens.dart';
import '../../tracker/session_controller.dart';

class CountdownOverlay extends StatefulWidget {
  const CountdownOverlay({super.key});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> {
  int _n = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_n > 1) {
          _n--;
        } else {
          _timer?.cancel();
          context.read<SessionController>().countdownComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.canvas,
      body: Stack(children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  tokens.brand.withValues(alpha: 0.25),
                  tokens.canvas,
                ],
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            '$_n',
            style: context.typo.statLarge.copyWith(
              fontSize: 160,
              color: tokens.brand,
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close),
            color: tokens.inkMuted,
            onPressed: () => context.read<SessionController>().cancelCountdown(),
          ),
        ),
      ]),
    );
  }
}

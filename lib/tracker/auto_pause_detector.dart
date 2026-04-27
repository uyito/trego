import 'dart:ui' show VoidCallback;

/// Observes speed samples and requests pause/resume via callbacks.
/// Pure — no I/O, no streams. Driven by explicit addSample() calls.
class AutoPauseDetector {
  AutoPauseDetector({
    this.pauseWindowSeconds = 10,
    this.pauseThresholdKmh = 1.0,
    this.resumeWindowSeconds = 3,
    this.resumeThresholdKmh = 2.0,
  });

  final int pauseWindowSeconds;
  final double pauseThresholdKmh;
  final int resumeWindowSeconds;
  final double resumeThresholdKmh;

  VoidCallback? onPauseRequested;
  VoidCallback? onResumeRequested;

  final List<_Sample> _window = [];
  bool _enabled = false;
  bool _pausedLocal = false; // tracks what we have told consumers

  void enable() {
    _enabled = true;
  }

  void disable() {
    _enabled = false;
    _window.clear();
    _pausedLocal = false;
  }

  void addSample(double speedKmh, DateTime at) {
    if (!_enabled) return;
    _window.add(_Sample(speedKmh, at));
    final maxAge = Duration(
      seconds: pauseWindowSeconds > resumeWindowSeconds
          ? pauseWindowSeconds
          : resumeWindowSeconds,
    );
    _window.removeWhere((s) => at.difference(s.at) > maxAge);

    if (!_pausedLocal) {
      final pauseCutoff = at.subtract(Duration(seconds: pauseWindowSeconds));
      final windowForPause = _window.where((s) => !s.at.isBefore(pauseCutoff)).toList();
      if (windowForPause.length >= pauseWindowSeconds + 1 &&
          windowForPause.every((s) => s.speedKmh < pauseThresholdKmh)) {
        _pausedLocal = true;
        onPauseRequested?.call();
      }
    } else {
      final resumeCutoff = at.subtract(Duration(seconds: resumeWindowSeconds));
      final windowForResume = _window.where((s) => s.at.isAfter(resumeCutoff)).toList();
      if (windowForResume.length >= resumeWindowSeconds &&
          windowForResume.every((s) => s.speedKmh > resumeThresholdKmh)) {
        _pausedLocal = false;
        onResumeRequested?.call();
      }
    }
  }
}

class _Sample {
  final double speedKmh;
  final DateTime at;
  _Sample(this.speedKmh, this.at);
}

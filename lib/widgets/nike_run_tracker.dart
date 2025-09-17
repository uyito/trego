import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../shared/app_theme.dart';

class NikeRunTracker extends StatefulWidget {
  final bool isRunning;
  final Duration duration;
  final double distance;
  final double pace;
  final int heartRate;
  final List<double> paceHistory;
  final VoidCallback? onStartStop;
  final VoidCallback? onPause;
  final VoidCallback? onReset;

  const NikeRunTracker({
    super.key,
    this.isRunning = false,
    this.duration = Duration.zero,
    this.distance = 0.0,
    this.pace = 0.0,
    this.heartRate = 0,
    this.paceHistory = const [],
    this.onStartStop,
    this.onPause,
    this.onReset,
  });

  @override
  State<NikeRunTracker> createState() => _NikeRunTrackerState();
}

class _NikeRunTrackerState extends State<NikeRunTracker>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isRunning) {
      _pulseController.repeat(reverse: true);
      _progressController.forward();
    }
  }

  @override
  void didUpdateWidget(NikeRunTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _pulseController.repeat(reverse: true);
        _progressController.forward();
      } else {
        _pulseController.stop();
        _progressController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryBlack,
            AppTheme.charcoalBlack,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildMainContent(),
            ),
            _buildControlButtons(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryWhite.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.close,
                color: AppTheme.primaryWhite,
                size: 24,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'OUTDOOR RUN',
            style: TextStyle(
              color: AppTheme.primaryWhite,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryWhite.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.settings,
              color: AppTheme.primaryWhite,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        const SizedBox(height: 40),
        _buildCentralTimer(),
        const SizedBox(height: 60),
        _buildStatsRow(),
        const SizedBox(height: 40),
        _buildPaceChart(),
      ],
    );
  }

  Widget _buildCentralTimer() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isRunning ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryRed.withValues(alpha: 0.3),
                      AppTheme.primaryRed.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Container(
                  width: 160,
                  height: 160,
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryRed,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryRed.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatDuration(widget.duration),
                          style: const TextStyle(
                            color: AppTheme.primaryWhite,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isRunning ? 'RUNNING' : 'PAUSED',
                          style: TextStyle(
                            color: AppTheme.primaryWhite.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          '${widget.distance.toStringAsFixed(2)} KM',
          style: const TextStyle(
            color: AppTheme.primaryWhite,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'TOTAL DISTANCE',
          style: TextStyle(
            color: AppTheme.primaryWhite.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            'PACE',
            '${widget.pace.toStringAsFixed(1)}\'',
            '/KM',
            AppTheme.workoutYellow,
          ),
          _buildStatItem(
            'HEART',
            '${widget.heartRate}',
            'BPM',
            AppTheme.recoveryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: unit,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.primaryWhite.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPaceChart() {
    if (widget.paceHistory.isEmpty) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: AppTheme.primaryWhite.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Pace data will appear here during your run',
            style: TextStyle(
              color: AppTheme.primaryWhite.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryWhite.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: NikePaceChartPainter(
          data: widget.paceHistory,
          color: AppTheme.primaryRed,
        ),
        size: const Size(double.infinity, 68),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Reset button
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryWhite.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
            ),
            child: IconButton(
              onPressed: widget.onReset,
              icon: const Icon(
                Icons.refresh,
                color: AppTheme.primaryWhite,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Start/Stop button
          Expanded(
            child: GestureDetector(
              onTap: widget.onStartStop,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: widget.isRunning
                      ? AppTheme.primaryRed
                      : AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isRunning
                              ? AppTheme.primaryRed
                              : AppTheme.primaryGreen)
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.isRunning ? 'STOP' : 'START',
                    style: const TextStyle(
                      color: AppTheme.primaryWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Pause button
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryWhite.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
            ),
            child: IconButton(
              onPressed: widget.onPause,
              icon: Icon(
                widget.isRunning ? Icons.pause : Icons.play_arrow,
                color: AppTheme.primaryWhite,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}

// Nike Pace Chart Painter
class NikePaceChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  NikePaceChartPainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final minValue = data.reduce((a, b) => math.min(a, b));
    final maxValue = data.reduce((a, b) => math.max(a, b));
    final range = maxValue - minValue;

    if (range == 0) return;

    final stepWidth = size.width / (data.length - 1);
    final path = Path();
    final gradientPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepWidth;
      final y = size.height - ((data[i] - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        gradientPath.moveTo(x, size.height);
        gradientPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        gradientPath.lineTo(x, y);
      }
    }

    // Draw gradient area
    gradientPath.lineTo(size.width, size.height);
    gradientPath.close();
    canvas.drawPath(gradientPath, gradientPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepWidth;
      final y = size.height - ((data[i] - minValue) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
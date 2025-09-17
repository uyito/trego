import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../shared/app_theme.dart';

// Nike Activity Ring (like Apple Watch rings)
class NikeActivityRings extends StatefulWidget {
  final double moveProgress;
  final double exerciseProgress;
  final double standProgress;
  final double size;

  const NikeActivityRings({
    super.key,
    required this.moveProgress,
    required this.exerciseProgress,
    required this.standProgress,
    this.size = 200,
  });

  @override
  State<NikeActivityRings> createState() => _NikeActivityRingsState();
}

class _NikeActivityRingsState extends State<NikeActivityRings>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _exerciseController;
  late AnimationController _standController;
  late Animation<double> _moveAnimation;
  late Animation<double> _exerciseAnimation;
  late Animation<double> _standAnimation;

  @override
  void initState() {
    super.initState();
    
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _exerciseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _standController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeOutCubic,
    );
    _exerciseAnimation = CurvedAnimation(
      parent: _exerciseController,
      curve: Curves.easeOutCubic,
    );
    _standAnimation = CurvedAnimation(
      parent: _standController,
      curve: Curves.easeOutCubic,
    );

    // Start animations with staggered timing
    _moveController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _exerciseController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _standController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _moveAnimation,
          _exerciseAnimation,
          _standAnimation,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: NikeActivityRingsPainter(
              moveProgress: widget.moveProgress * _moveAnimation.value,
              exerciseProgress: widget.exerciseProgress * _exerciseAnimation.value,
              standProgress: widget.standProgress * _standAnimation.value,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _exerciseController.dispose();
    _standController.dispose();
    super.dispose();
  }
}

// Custom Painter for Activity Rings
class NikeActivityRingsPainter extends CustomPainter {
  final double moveProgress;
  final double exerciseProgress;
  final double standProgress;

  NikeActivityRingsPainter({
    required this.moveProgress,
    required this.exerciseProgress,
    required this.standProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 12.0;
    const ringSpacing = 6.0;

    // Ring radii (from outer to inner)
    final outerRadius = (size.width / 2) - strokeWidth / 2;
    final middleRadius = outerRadius - strokeWidth - ringSpacing;
    final innerRadius = middleRadius - strokeWidth - ringSpacing;

    // Draw Move ring (outer, red)
    _drawRing(
      canvas,
      center,
      outerRadius,
      strokeWidth,
      AppTheme.primaryRed,
      moveProgress,
    );

    // Draw Exercise ring (middle, green)
    _drawRing(
      canvas,
      center,
      middleRadius,
      strokeWidth,
      AppTheme.primaryGreen,
      exerciseProgress,
    );

    // Draw Stand ring (inner, blue)
    _drawRing(
      canvas,
      center,
      innerRadius,
      strokeWidth,
      AppTheme.primaryBlue,
      standProgress,
    );
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeWidth,
    Color color,
    double progress,
  ) {
    // Background ring
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Nike Pulse Animation
class NikePulseAnimation extends StatefulWidget {
  final Widget child;
  final Color color;
  final Duration duration;
  final double minRadius;
  final double maxRadius;
  final int pulseCount;

  const NikePulseAnimation({
    super.key,
    required this.child,
    required this.color,
    this.duration = const Duration(milliseconds: 1500),
    this.minRadius = 0.0,
    this.maxRadius = 100.0,
    this.pulseCount = 3,
  });

  @override
  State<NikePulseAnimation> createState() => _NikePulseAnimationState();
}

class _NikePulseAnimationState extends State<NikePulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: NikePulsePainter(
            progress: _controller.value,
            color: widget.color,
            minRadius: widget.minRadius,
            maxRadius: widget.maxRadius,
            pulseCount: widget.pulseCount,
          ),
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Custom Painter for Pulse Animation
class NikePulsePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double minRadius;
  final double maxRadius;
  final int pulseCount;

  NikePulsePainter({
    required this.progress,
    required this.color,
    required this.minRadius,
    required this.maxRadius,
    required this.pulseCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 0; i < pulseCount; i++) {
      final pulseProgress = (progress + (i / pulseCount)) % 1.0;
      final radius = minRadius + (maxRadius - minRadius) * pulseProgress;
      final opacity = (1.0 - pulseProgress) * 0.6;
      
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Nike Loading Animation
class NikeLoadingAnimation extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const NikeLoadingAnimation({
    super.key,
    this.size = 40,
    this.color = AppTheme.primaryRed,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<NikeLoadingAnimation> createState() => _NikeLoadingAnimationState();
}

class _NikeLoadingAnimationState extends State<NikeLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: NikeLoadingPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Custom Painter for Loading Animation
class NikeLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;

  NikeLoadingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dotCount = 8;
    const dotRadius = 3.0;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * math.pi / dotCount) * i;
      final dotProgress = (progress + (i / dotCount)) % 1.0;
      final opacity = math.sin(dotProgress * math.pi);
      
      final x = center.dx + radius * 0.7 * math.cos(angle);
      final y = center.dy + radius * 0.7 * math.sin(angle);
      
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Nike Progress Wave Animation
class NikeProgressWave extends StatefulWidget {
  final double progress;
  final Color color;
  final double height;
  final Duration duration;

  const NikeProgressWave({
    super.key,
    required this.progress,
    required this.color,
    this.height = 100,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<NikeProgressWave> createState() => _NikeProgressWaveState();
}

class _NikeProgressWaveState extends State<NikeProgressWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: NikeWavePainter(
                progress: widget.progress,
                waveProgress: _controller.value,
                color: widget.color,
              ),
              size: Size(double.infinity, widget.height),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Custom Painter for Wave Animation
class NikeWavePainter extends CustomPainter {
  final double progress;
  final double waveProgress;
  final Color color;

  NikeWavePainter({
    required this.progress,
    required this.waveProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw wave
    final path = Path();
    final waveHeight = size.height * progress;
    final amplitude = 8.0;
    final frequency = 2 * math.pi / size.width;

    path.moveTo(0, size.height);
    path.lineTo(0, size.height - waveHeight);

    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height - waveHeight +
          amplitude * math.sin(frequency * x + waveProgress * 2 * math.pi);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Nike Confetti Animation
class NikeConfettiAnimation extends StatefulWidget {
  final bool isActive;
  final Duration duration;

  const NikeConfettiAnimation({
    super.key,
    required this.isActive,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<NikeConfettiAnimation> createState() => _NikeConfettiAnimationState();
}

class _NikeConfettiAnimationState extends State<NikeConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<ConfettiParticle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _generateParticles();
  }

  void _generateParticles() {
    final random = math.Random();
    particles = List.generate(50, (index) {
      return ConfettiParticle(
        x: random.nextDouble(),
        y: -0.1,
        velocityX: (random.nextDouble() - 0.5) * 2,
        velocityY: random.nextDouble() * 3 + 1,
        color: [
          AppTheme.primaryRed,
          AppTheme.primaryGreen,
          AppTheme.primaryBlue,
          AppTheme.nikeOrange,
          AppTheme.workoutYellow,
        ][random.nextInt(5)],
        size: random.nextDouble() * 6 + 2,
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 10,
      );
    });
  }

  @override
  void didUpdateWidget(NikeConfettiAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _generateParticles();
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: NikeConfettiPainter(
            progress: _controller.value,
            particles: particles,
          ),
          size: const Size(double.infinity, double.infinity),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Confetti Particle Model
class ConfettiParticle {
  double x;
  double y;
  final double velocityX;
  final double velocityY;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

// Custom Painter for Confetti Animation
class NikeConfettiPainter extends CustomPainter {
  final double progress;
  final List<ConfettiParticle> particles;

  NikeConfettiPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = particle.x * size.width + 
                 particle.velocityX * progress * size.width * 0.1;
      final y = particle.y * size.height + 
                 particle.velocityY * progress * size.height;
      
      if (y > size.height) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + particle.rotationSpeed * progress);
      
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress * 0.5)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
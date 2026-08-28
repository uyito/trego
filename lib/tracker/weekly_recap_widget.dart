import 'package:flutter/material.dart';
import 'package:trego/tracker/run_model.dart' as run_model;
import 'package:trego/tracker/run_service.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';

class WeeklyRecapWidget extends StatefulWidget {
  const WeeklyRecapWidget({super.key});

  @override
  State<WeeklyRecapWidget> createState() => _WeeklyRecapWidgetState();
}

class _WeeklyRecapWidgetState extends State<WeeklyRecapWidget>
    with TickerProviderStateMixin {
  final RunService _runService = RunService();
  
  run_model.RunStats? _weeklyStats;
  bool _isLoading = true;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _loadWeeklyStats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklyStats() async {
    try {
      final stats = await _runService.getWeeklyStats();
      if (mounted) {
        setState(() {
          _weeklyStats = stats;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      print('Error loading weekly stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (_isLoading) {
      return Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(Radii.standardCard),
          boxShadow: [
            BoxShadow(
              color: tokens.ink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(tokens.brand),
          ),
        ),
      );
    }

    if (_weeklyStats == null || _weeklyStats!.totalRuns == 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(Radii.standardCard),
          boxShadow: [
            BoxShadow(
              color: tokens.ink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: tokens.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: tokens.brand,
                  size: 16,
                ),
              ),
              const SizedBox(width: Space.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Weekly Recap',
                      style: context.typo.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'No runs this week yet. Start your first run!',
                      style: context.typo.label.copyWith(
                        color: tokens.inkMuted,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tokens.brandContainerStart,
              tokens.brandContainerEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(Radii.standardCard),
          boxShadow: [
            BoxShadow(
              color: tokens.brand.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: tokens.onBrand.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: tokens.onBrand,
                  size: 16,
                ),
              ),
              const SizedBox(width: Space.md),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: _buildStatItem(
                        context,
                        icon: '📏',
                        value: '${_weeklyStats!.totalDistance.toStringAsFixed(1)}',
                        label: 'km',
                        color: tokens.onBrand,
                      ),
                    ),
                    Flexible(
                      child: _buildStatItem(
                        context,
                        icon: '⏱️',
                        value: run_model.Run.formatDuration(_weeklyStats!.totalTime),
                        label: 'time',
                        color: tokens.onBrand,
                      ),
                    ),
                    Flexible(
                      child: _buildStatItem(
                        context,
                        icon: '⚡',
                        value: run_model.Run.formatPace(_weeklyStats!.averagePace),
                        label: 'avg pace',
                        color: tokens.onBrand,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'This Week',
                    style: context.typo.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.onBrand,
                    ),
                  ),
                  Text(
                    '${_weeklyStats!.totalRuns} runs',
                    style: context.typo.label.copyWith(
                      fontWeight: FontWeight.w500,
                      color: tokens.onBrand,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 10),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: context.typo.label.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0,
          ),
        ),
        Text(
          label,
          style: context.typo.label.copyWith(
            fontSize: 7,
            fontWeight: FontWeight.w400,
            color: color.withValues(alpha: 0.8),
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
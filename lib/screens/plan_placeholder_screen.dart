import 'package:flutter/material.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../widgets/core/trego_app_bar.dart';
import '../widgets/core/trego_scaffold.dart';
import '../widgets/core/trego_button.dart';
import '../workouts/workout_hub.dart';

class PlanPlaceholderScreen extends StatelessWidget {
  const PlanPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TregoScaffold(
      appBar: const TregoAppBar(title: 'Plan'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 48, color: tokens.inkMuted),
              const SizedBox(height: Space.md),
              Text('Training plans coming soon', style: context.typo.title),
              const SizedBox(height: Space.sm),
              Text(
                'Your AI training plan will live here.',
                style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
              ),
              const SizedBox(height: Space.xl),
              TregoButton(
                label: 'Browse existing workouts',
                variant: TregoButtonVariant.secondary,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WorkoutHub()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trego/workouts/workout_service.dart';
import 'package:trego/auth/auth_service.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // Lazy so construction (which touches Firestore) is deferred until the
  // signed-in StreamBuilder path actually reads it.
  late final WorkoutService _workoutService = WorkoutService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    try {
      _userId = AuthService().currentUser?.uid;
    } catch (_) {
      // Auth unavailable (e.g. Firebase not configured in this context);
      // treat as signed-out.
      _userId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        backgroundColor: tokens.surfaceSunken,
        elevation: 0,
        title: Text(
          'Workout History',
          style: typo.title.copyWith(color: tokens.ink),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tokens.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _userId == null
          ? const Center(
              child: Text('Please sign in to view workout history'),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _workoutService.getUserWorkoutPlans(_userId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: tokens.brand,
                    ),
                  );
                }

                final workouts = snapshot.data?.docs ?? [];

                if (workouts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          size: 64,
                          color: tokens.inkMuted,
                        ),
                        const SizedBox(height: Space.lg),
                        Text(
                          'No workout history yet',
                          style: typo.titleSmall.copyWith(color: tokens.inkMuted),
                        ),
                        const SizedBox(height: Space.sm),
                        Text(
                          'Complete your first workout to see it here!',
                          style: typo.body.copyWith(color: tokens.inkMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(Space.lg),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index].data() as Map<String, dynamic>;
                    final completed = workout['completed'] as bool? ?? false;
                    final day = workout['day'] as String? ?? '';
                    final focus = workout['focus'] as String? ?? '';
                    final weekStart = workout['weekStart'] as String? ?? '';

                    return Card(
                      color: tokens.surface,
                      margin: const EdgeInsets.only(bottom: Space.md),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(Space.sm),
                          decoration: BoxDecoration(
                            color: completed
                                ? tokens.success.withValues(alpha: 0.1)
                                : tokens.brand.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(Space.sm),
                          ),
                          child: Icon(
                            completed ? Icons.check_rounded : Icons.fitness_center_rounded,
                            color: completed ? tokens.success : tokens.brand,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          day,
                          style: typo.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: completed ? tokens.success : tokens.ink,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(focus, style: typo.body.copyWith(color: tokens.ink)),
                            Text(
                              'Week of $weekStart',
                              style: typo.bodySmall.copyWith(color: tokens.inkMuted),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: completed ? tokens.success : tokens.inkMuted,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
} 
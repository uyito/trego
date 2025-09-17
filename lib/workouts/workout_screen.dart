import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trego/workouts/workout_service.dart';
import 'package:trego/auth/auth_service.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final WorkoutService _workoutService = WorkoutService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = AuthService().currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Workout History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
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
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE31E24),
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
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workout history yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your first workout to see it here!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index].data() as Map<String, dynamic>;
                    final completed = workout['completed'] as bool? ?? false;
                    final day = workout['day'] as String? ?? '';
                    final focus = workout['focus'] as String? ?? '';
                    final weekStart = workout['weekStart'] as String? ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: completed 
                                ? const Color(0xFF00C851).withValues(alpha: 0.1)
                                : const Color(0xFFE31E24).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            completed ? Icons.check_rounded : Icons.fitness_center_rounded,
                            color: completed ? const Color(0xFF00C851) : const Color(0xFFE31E24),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: completed ? const Color(0xFF00C851) : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(focus),
                            Text(
                              'Week of $weekStart',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: completed ? const Color(0xFF00C851) : Colors.grey,
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
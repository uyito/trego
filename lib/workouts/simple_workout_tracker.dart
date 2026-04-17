import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SimpleWorkoutTracker extends StatefulWidget {
  const SimpleWorkoutTracker({super.key});

  @override
  State<SimpleWorkoutTracker> createState() => _SimpleWorkoutTrackerState();
}

class _SimpleWorkoutTrackerState extends State<SimpleWorkoutTracker> {
  bool _isWorkoutActive = false;
  DateTime? _workoutStartTime;
  Duration _workoutDuration = Duration.zero;
  String _workoutType = 'General Workout';
  int _sets = 0;
  int _reps = 0;
  
  final List<String> _workoutTypes = [
    'General Workout',
    'Push-ups',
    'Squats',
    'Running',
    'Weight Training',
    'Yoga',
    'Cardio',
  ];

  void _startWorkout() {
    setState(() {
      _isWorkoutActive = true;
      _workoutStartTime = DateTime.now();
      _workoutDuration = Duration.zero;
    });
    
    // Start timer
    _startTimer();
  }

  void _stopWorkout() async {
    setState(() {
      _isWorkoutActive = false;
    });
    
    // Save workout to Firebase
    await _saveWorkout();
    
    // Show completion dialog
    _showWorkoutCompleteDialog();
  }

  void _startTimer() {
    if (_isWorkoutActive) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isWorkoutActive && _workoutStartTime != null) {
          setState(() {
            _workoutDuration = DateTime.now().difference(_workoutStartTime!);
          });
          _startTimer();
        }
      });
    }
  }

  Future<void> _saveWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .add({
        'type': _workoutType,
        'duration': _workoutDuration.inMinutes,
        'sets': _sets,
        'reps': _reps,
        'date': _workoutStartTime?.toIso8601String(),
        'completed': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving workout: $e');
    }
  }

  void _showWorkoutCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout Complete! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Workout Type: $_workoutType'),
            Text('Duration: ${_formatDuration(_workoutDuration)}'),
            if (_sets > 0) Text('Sets: $_sets'),
            if (_reps > 0) Text('Reps: $_reps'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetWorkout();
            },
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _resetWorkout() {
    setState(() {
      _workoutStartTime = null;
      _workoutDuration = Duration.zero;
      _sets = 0;
      _reps = 0;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracker'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Workout Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Workout Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _workoutType,
                      items: _workoutTypes.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      )).toList(),
                      onChanged: _isWorkoutActive ? null : (value) {
                        setState(() {
                          _workoutType = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Timer Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('Workout Timer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text(
                      _formatDuration(_workoutDuration),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isWorkoutActive ? _stopWorkout : _startWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isWorkoutActive ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _isWorkoutActive ? 'Stop Workout' : 'Start Workout',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sets and Reps Counter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Track Your Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Sets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: _sets > 0 ? () => setState(() => _sets--) : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text('$_sets', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    onPressed: () => setState(() => _sets++),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Reps', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: _reps > 0 ? () => setState(() => _reps--) : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text('$_reps', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    onPressed: () => setState(() => _reps++),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recent Workouts
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recent Workouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildRecentWorkouts(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentWorkouts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view workouts'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading workouts'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workouts = snapshot.data?.docs ?? [];
        
        if (workouts.isEmpty) {
          return const Center(
            child: Text(
              'No workouts yet!\nStart your first workout above.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workout = workouts[index].data() as Map<String, dynamic>;
            final duration = workout['duration'] ?? 0;
            final type = workout['type'] ?? 'Unknown';
            final sets = workout['sets'] ?? 0;
            final reps = workout['reps'] ?? 0;
            
            return ListTile(
              leading: const Icon(Icons.fitness_center, color: Colors.blue),
              title: Text(type),
              subtitle: Text('${duration}min • Sets: $sets • Reps: $reps'),
              trailing: const Icon(Icons.chevron_right),
            );
          },
        );
      },
    );
  }
}
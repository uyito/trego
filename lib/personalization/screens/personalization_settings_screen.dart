import 'package:flutter/material.dart';
import '../personalization_service.dart';

class PersonalizationSettingsScreen extends StatefulWidget {
  const PersonalizationSettingsScreen({super.key});

  @override
  State<PersonalizationSettingsScreen> createState() => _PersonalizationSettingsScreenState();
}

class _PersonalizationSettingsScreenState extends State<PersonalizationSettingsScreen> {
  final PersonalizationService _personalizationService = PersonalizationService();
  
  // Workout preferences
  List<String> _workoutPreferences = [];
  List<String> _availableWorkoutTypes = [
    'Cardio',
    'Strength Training',
    'HIIT',
    'Yoga',
    'Pilates',
    'Running',
    'Cycling',
    'Swimming',
    'Boxing',
    'Dance',
    'Flexibility',
    'Balance',
  ];

  // Nutrition preferences
  List<String> _nutritionPreferences = [];
  List<String> _availableNutritionTypes = [
    'Vegetarian',
    'Vegan',
    'Keto',
    'Paleo',
    'Mediterranean',
    'Low Carb',
    'High Protein',
    'Gluten Free',
    'Dairy Free',
    'Low Sodium',
    'Whole Foods',
    'Intermittent Fasting',
  ];

  // Goals
  Map<String, dynamic> _goals = {
    'primaryGoal': 'general_fitness',
    'weeklyWorkoutTarget': 3,
    'dailyCalorieTarget': 2000,
    'weightGoal': null,
    'targetWeight': null,
    'timeFrame': 12, // weeks
  };

  // Restrictions and preferences
  Map<String, dynamic> _restrictions = {
    'injuries': <String>[],
    'equipment': <String>[],
    'timeConstraints': {
      'maxWorkoutDuration': 60,
      'preferredTimes': <String>[],
    },
    'allergies': <String>[],
    'dislikedFoods': <String>[],
  };

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPreferences();
  }

  Future<void> _loadCurrentPreferences() async {
    setState(() => _isLoading = true);
    
    try {
      // Load current preferences from backend if available
      // For now, using default values
      await Future.delayed(const Duration(seconds: 1)); // Simulate loading
      
      setState(() {
        _workoutPreferences = ['Cardio', 'Strength Training'];
        _nutritionPreferences = ['High Protein'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load preferences')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    
    try {
      final success = await _personalizationService.updatePreferences(
        workoutPreferences: _workoutPreferences,
        nutritionPreferences: _nutritionPreferences,
        goals: _goals,
        restrictions: _restrictions,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved! Recommendations will improve.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save preferences')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Personalization Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalization Settings'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePreferences,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGoalsSection(),
          const SizedBox(height: 24),
          _buildWorkoutPreferencesSection(),
          const SizedBox(height: 24),
          _buildNutritionPreferencesSection(),
          const SizedBox(height: 24),
          _buildRestrictionsSection(),
          const SizedBox(height: 24),
          _buildAdvancedSection(),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined),
                const SizedBox(width: 8),
                Text(
                  'Goals',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _goals['primaryGoal'],
              decoration: const InputDecoration(labelText: 'Primary Goal'),
              items: const [
                DropdownMenuItem(value: 'lose_weight', child: Text('Lose Weight')),
                DropdownMenuItem(value: 'gain_muscle', child: Text('Gain Muscle')),
                DropdownMenuItem(value: 'general_fitness', child: Text('General Fitness')),
                DropdownMenuItem(value: 'endurance', child: Text('Build Endurance')),
                DropdownMenuItem(value: 'strength', child: Text('Build Strength')),
                DropdownMenuItem(value: 'flexibility', child: Text('Improve Flexibility')),
              ],
              onChanged: (value) => setState(() => _goals['primaryGoal'] = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _goals['weeklyWorkoutTarget'].toString(),
                    decoration: const InputDecoration(labelText: 'Weekly Workout Target'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _goals['weeklyWorkoutTarget'] = int.tryParse(value) ?? 3,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _goals['dailyCalorieTarget'].toString(),
                    decoration: const InputDecoration(labelText: 'Daily Calorie Target'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _goals['dailyCalorieTarget'] = int.tryParse(value) ?? 2000,
                  ),
                ),
              ],
            ),
            if (_goals['primaryGoal'] == 'lose_weight' || _goals['primaryGoal'] == 'gain_muscle') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _goals['targetWeight']?.toString() ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Target Weight (kg)',
                        hintText: 'Optional',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _goals['targetWeight'] = double.tryParse(value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _goals['timeFrame'].toString(),
                      decoration: const InputDecoration(labelText: 'Timeframe (weeks)'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _goals['timeFrame'] = int.tryParse(value) ?? 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center),
                const SizedBox(width: 8),
                Text(
                  'Workout Preferences',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Select types of workouts you enjoy:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableWorkoutTypes.map((type) {
                final isSelected = _workoutPreferences.contains(type);
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _workoutPreferences.add(type);
                      } else {
                        _workoutPreferences.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant),
                const SizedBox(width: 8),
                Text(
                  'Nutrition Preferences',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Select your dietary preferences:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableNutritionTypes.map((type) {
                final isSelected = _nutritionPreferences.contains(type);
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _nutritionPreferences.add(type);
                      } else {
                        _nutritionPreferences.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestrictionsSection() {
    final timeConstraints = _restrictions['timeConstraints'] as Map<String, dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_outlined),
                const SizedBox(width: 8),
                Text(
                  'Restrictions & Limitations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Injuries or Limitations',
                hintText: 'e.g., knee injury, back problems',
              ),
              onChanged: (value) {
                _restrictions['injuries'] = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Available Equipment',
                hintText: 'e.g., dumbbells, resistance bands',
              ),
              onChanged: (value) {
                _restrictions['equipment'] = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: timeConstraints['maxWorkoutDuration'].toString(),
              decoration: const InputDecoration(labelText: 'Max Workout Duration (minutes)'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                timeConstraints['maxWorkoutDuration'] = int.tryParse(value) ?? 60;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Food Allergies',
                hintText: 'e.g., nuts, dairy, shellfish',
              ),
              onChanged: (value) {
                _restrictions['allergies'] = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_outlined),
                const SizedBox(width: 8),
                Text(
                  'Advanced Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Reset Personalization'),
              subtitle: const Text('Start fresh with new recommendations'),
              trailing: const Icon(Icons.refresh),
              onTap: _showResetDialog,
            ),
            ListTile(
              title: const Text('Export Preferences'),
              subtitle: const Text('Backup your personalization settings'),
              trailing: const Icon(Icons.download),
              onTap: _exportPreferences,
            ),
            ListTile(
              title: const Text('Privacy Settings'),
              subtitle: const Text('Manage how your data is used'),
              trailing: const Icon(Icons.privacy_tip_outlined),
              onTap: () => Navigator.pushNamed(context, '/privacy/personalization'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Personalization?'),
        content: const Text(
          'This will clear all your preferences and start building recommendations from scratch. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPersonalization();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPersonalization() async {
    try {
      final success = await _personalizationService.resetPersonalization();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personalization reset successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset local state
        setState(() {
          _workoutPreferences.clear();
          _nutritionPreferences.clear();
          _goals = {
            'primaryGoal': 'general_fitness',
            'weeklyWorkoutTarget': 3,
            'dailyCalorieTarget': 2000,
            'weightGoal': null,
            'targetWeight': null,
            'timeFrame': 12,
          };
          _restrictions = {
            'injuries': <String>[],
            'equipment': <String>[],
            'timeConstraints': {
              'maxWorkoutDuration': 60,
              'preferredTimes': <String>[],
            },
            'allergies': <String>[],
            'dislikedFoods': <String>[],
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reset personalization')),
        );
      }
    }
  }

  void _exportPreferences() {
    final preferences = {
      'workoutPreferences': _workoutPreferences,
      'nutritionPreferences': _nutritionPreferences,
      'goals': _goals,
      'restrictions': _restrictions,
      'exportedAt': DateTime.now().toIso8601String(),
    };

    // TODO: Implement actual export functionality
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export feature coming soon!')),
      );
    }
  }
}
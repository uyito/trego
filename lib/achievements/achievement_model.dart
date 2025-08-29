class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String category;
  final int requirement;
  final String unit;
  final DateTime? earnedAt;
  final bool isEarned;
  final String? progress;
  final int? currentValue;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.requirement,
    required this.unit,
    this.earnedAt,
    this.isEarned = false,
    this.progress,
    this.currentValue,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      category: map['category'] ?? '',
      requirement: map['requirement'] ?? 0,
      unit: map['unit'] ?? '',
      earnedAt: map['earnedAt'] != null 
          ? DateTime.parse(map['earnedAt']) 
          : null,
      isEarned: map['isEarned'] ?? false,
      progress: map['progress'],
      currentValue: map['currentValue'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category,
      'requirement': requirement,
      'unit': unit,
      'earnedAt': earnedAt?.toIso8601String(),
      'isEarned': isEarned,
      'progress': progress,
      'currentValue': currentValue,
    };
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    String? category,
    int? requirement,
    String? unit,
    DateTime? earnedAt,
    bool? isEarned,
    String? progress,
    int? currentValue,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      requirement: requirement ?? this.requirement,
      unit: unit ?? this.unit,
      earnedAt: earnedAt ?? this.earnedAt,
      isEarned: isEarned ?? this.isEarned,
      progress: progress ?? this.progress,
      currentValue: currentValue ?? this.currentValue,
    );
  }
}

class AchievementCategory {
  final String id;
  final String name;
  final String icon;
  final String description;

  AchievementCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}

// Predefined achievement categories
final List<AchievementCategory> achievementCategories = [
  AchievementCategory(
    id: 'running',
    name: 'Running',
    icon: '🏃',
    description: 'Distance and speed milestones',
  ),
  AchievementCategory(
    id: 'streak',
    name: 'Streaks',
    icon: '🔥',
    description: 'Consistency achievements',
  ),
  AchievementCategory(
    id: 'workout',
    name: 'Workouts',
    icon: '💪',
    description: 'Strength and fitness goals',
  ),
  AchievementCategory(
    id: 'nutrition',
    name: 'Nutrition',
    icon: '🥗',
    description: 'Healthy eating habits',
  ),
];

// Predefined achievements
final List<Achievement> predefinedAchievements = [
  // Running achievements
  Achievement(
    id: 'first_run',
    title: 'First Steps',
    description: 'Complete your first run',
    icon: '👟',
    category: 'running',
    requirement: 1,
    unit: 'run',
  ),
  Achievement(
    id: '5k_runner',
    title: '5K Runner',
    description: 'Complete a 5K run',
    icon: '🏃‍♂️',
    category: 'running',
    requirement: 5,
    unit: 'km',
  ),
  Achievement(
    id: '10k_runner',
    title: '10K Runner',
    description: 'Complete a 10K run',
    icon: '🏃‍♀️',
    category: 'running',
    requirement: 10,
    unit: 'km',
  ),
  Achievement(
    id: 'marathon_ready',
    title: 'Marathon Ready',
    description: 'Complete a half marathon',
    icon: '🏃',
    category: 'running',
    requirement: 21,
    unit: 'km',
  ),
  Achievement(
    id: 'speed_demon',
    title: 'Speed Demon',
    description: 'Run 5K under 25 minutes',
    icon: '⚡',
    category: 'running',
    requirement: 25,
    unit: 'minutes',
  ),
  
  // Streak achievements
  Achievement(
    id: '3_day_streak',
    title: 'Getting Started',
    description: 'Work out for 3 days in a row',
    icon: '🔥',
    category: 'streak',
    requirement: 3,
    unit: 'days',
  ),
  Achievement(
    id: '7_day_streak',
    title: 'Week Warrior',
    description: 'Work out for 7 days in a row',
    icon: '🔥🔥',
    category: 'streak',
    requirement: 7,
    unit: 'days',
  ),
  Achievement(
    id: '30_day_streak',
    title: 'Month Master',
    description: 'Work out for 30 days in a row',
    icon: '🔥🔥🔥',
    category: 'streak',
    requirement: 30,
    unit: 'days',
  ),
  
  // Workout achievements
  Achievement(
    id: 'first_workout',
    title: 'First Workout',
    description: 'Complete your first workout',
    icon: '💪',
    category: 'workout',
    requirement: 1,
    unit: 'workout',
  ),
  Achievement(
    id: '10_workouts',
    title: 'Dedicated',
    description: 'Complete 10 workouts',
    icon: '💪💪',
    category: 'workout',
    requirement: 10,
    unit: 'workouts',
  ),
  Achievement(
    id: '50_workouts',
    title: 'Fitness Enthusiast',
    description: 'Complete 50 workouts',
    icon: '💪💪💪',
    category: 'workout',
    requirement: 50,
    unit: 'workouts',
  ),
  
  // Nutrition achievements
  Achievement(
    id: 'water_champion',
    title: 'Water Champion',
    description: 'Drink 8 cups of water for 7 days',
    icon: '💧',
    category: 'nutrition',
    requirement: 7,
    unit: 'days',
  ),
  Achievement(
    id: 'calorie_tracker',
    title: 'Calorie Tracker',
    description: 'Track calories for 14 days',
    icon: '📊',
    category: 'nutrition',
    requirement: 14,
    unit: 'days',
  ),
]; 
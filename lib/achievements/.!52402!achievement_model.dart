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

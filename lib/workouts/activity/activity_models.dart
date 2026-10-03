class ExerciseSet {
  int? setNumber, reps, rpe, restTime;
  double? weight;
  ExerciseSet({this.setNumber, this.reps, this.weight, this.rpe, this.restTime});

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (setNumber != null) m['setNumber'] = setNumber;
    if (reps != null) m['reps'] = reps;
    if (weight != null) m['weight'] = weight;
    if (rpe != null) m['rpe'] = rpe;
    if (restTime != null) m['restTime'] = restTime;
    return m;
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> j) => ExerciseSet(
        setNumber: (j['setNumber'] as num?)?.toInt(),
        reps: (j['reps'] as num?)?.toInt(),
        weight: (j['weight'] as num?)?.toDouble(),
        rpe: (j['rpe'] as num?)?.toInt(),
        restTime: (j['restTime'] as num?)?.toInt(),
      );
}

class ExerciseLog {
  String exerciseId, name;
  List<ExerciseSet> sets;
  ExerciseLog({required this.exerciseId, required this.name, this.sets = const []});

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'name': name,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory ExerciseLog.fromJson(Map<String, dynamic> j) => ExerciseLog(
        exerciseId: j['exerciseId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        sets: ((j['sets'] as List?) ?? const [])
            .map((e) => ExerciseSet.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class ActivitySession {
  String? id, sessionName, notes, stroke;
  String activityType, logKind;
  int? duration, perceivedExertion;
  double? distance, elevationGain, avgPace;
  List<ExerciseLog> exercises;
  DateTime? createdAt;

  ActivitySession({
    this.id, required this.activityType, required this.logKind,
    this.sessionName, this.notes, this.stroke, this.duration,
    this.perceivedExertion, this.distance, this.elevationGain, this.avgPace,
    this.exercises = const [], this.createdAt,
  });

  Map<String, dynamic> toLogPayload() {
    final m = <String, dynamic>{'activityType': activityType, 'logKind': logKind};
    if (sessionName != null) m['sessionName'] = sessionName;
    if (notes != null) m['notes'] = notes;
    if (duration != null) m['duration'] = duration;
    if (distance != null) m['distance'] = distance;
    if (elevationGain != null) m['elevationGain'] = elevationGain;
    if (stroke != null) m['stroke'] = stroke;
    if (perceivedExertion != null) m['perceivedExertion'] = perceivedExertion;
    if (exercises.isNotEmpty) m['exercises'] = exercises.map((e) => e.toJson()).toList();
    return m;
  }

  factory ActivitySession.fromJson(Map<String, dynamic> j) => ActivitySession(
        id: j['id'] as String?,
        activityType: j['activityType'] as String? ?? '',
        logKind: j['logKind'] as String? ?? 'duration',
        sessionName: j['sessionName'] as String?,
        notes: j['notes'] as String?,
        stroke: j['stroke'] as String?,
        duration: (j['duration'] as num?)?.toInt(),
        perceivedExertion: (j['perceivedExertion'] as num?)?.toInt(),
        distance: (j['distance'] as num?)?.toDouble(),
        elevationGain: (j['elevationGain'] as num?)?.toDouble(),
        avgPace: (j['avgPace'] as num?)?.toDouble(),
        exercises: ((j['exercises'] as List?) ?? const [])
            .map((e) => ExerciseLog.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: _parseDate(j['startTime']) ?? _parseDate(j['createdAt']),
      );

  static DateTime? _parseDate(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
}

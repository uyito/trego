enum ActivityLogKind { strength, distanceCardio, sport, duration }

class Activity {
  final String id;
  final String name;
  final String category; // 'Cardio' | 'Sport' | 'Strength' | 'Mind-body'
  final ActivityLogKind logKind;
  final bool tracksElevation;
  final bool tracksStroke;

  const Activity({
    required this.id,
    required this.name,
    required this.category,
    required this.logKind,
    this.tracksElevation = false,
    this.tracksStroke = false,
  });
}

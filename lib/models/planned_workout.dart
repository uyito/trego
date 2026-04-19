class PlannedWorkout {
  final String title;        // e.g., "Tempo Run"
  final String metaLine;     // e.g., "30 min · 5.2 km · Zone 3–4"
  final String todayLabel;   // e.g., "Today · Tuesday"

  const PlannedWorkout({
    required this.title,
    required this.metaLine,
    required this.todayLabel,
  });
}

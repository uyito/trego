class Activity {
  final String userName;
  final String timestampLabel;    // e.g., "Today at 8:04 AM" or "2h ago"
  final String? locationLabel;    // e.g., "Austin, TX"
  final String title;             // e.g., "Morning Long Run"
  final double distanceKm;
  final String pacePerKm;         // e.g., "4:56"
  final String durationLabel;     // e.g., "40:28"
  final int kudosCount;
  final int commentCount;
  final bool userHasKudosed;

  const Activity({
    required this.userName,
    required this.timestampLabel,
    this.locationLabel,
    required this.title,
    required this.distanceKm,
    required this.pacePerKm,
    required this.durationLabel,
    this.kudosCount = 0,
    this.commentCount = 0,
    this.userHasKudosed = false,
  });
}

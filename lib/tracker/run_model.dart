import 'package:cloud_firestore/cloud_firestore.dart';

class Run {
  final String? id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final double distance; // in kilometers
  final double averagePace; // minutes per kilometer
  final List<LatLng> route;
  final String? notes;
  final bool isSyncedFromWatch;
  final Map<String, dynamic>? additionalData;

  Run({
    this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.distance,
    required this.averagePace,
    required this.route,
    this.notes,
    this.isSyncedFromWatch = false,
    this.additionalData,
  });

  factory Run.fromMap(Map<String, dynamic> map, String documentId) {
    return Run(
      id: documentId,
      userId: map['userId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
      duration: Duration(seconds: map['durationSeconds'] ?? 0),
      distance: (map['distance'] ?? 0.0).toDouble(),
      averagePace: (map['averagePace'] ?? 0.0).toDouble(),
      route: _parseRoute(map['route'] ?? []),
      notes: map['notes'],
      isSyncedFromWatch: map['isSyncedFromWatch'] ?? false,
      additionalData: map['additionalData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationSeconds': duration.inSeconds,
      'distance': distance,
      'averagePace': averagePace,
      'route': _serializeRoute(route),
      'notes': notes,
      'isSyncedFromWatch': isSyncedFromWatch,
      'additionalData': additionalData,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  static List<LatLng> _parseRoute(List<dynamic> routeData) {
    return routeData.map((point) {
      if (point is Map<String, dynamic>) {
        return LatLng(
          (point['latitude'] ?? 0.0).toDouble(),
          (point['longitude'] ?? 0.0).toDouble(),
        );
      }
      return const LatLng(0, 0);
    }).toList();
  }

  static List<Map<String, double>> _serializeRoute(List<LatLng> route) {
    return route.map((point) => {
      'latitude': point.latitude,
      'longitude': point.longitude,
    }).toList();
  }

  // Calculate pace in minutes per kilometer
  static double calculatePace(Duration duration, double distanceKm) {
    if (distanceKm <= 0) return 0.0;
    return duration.inMinutes / distanceKm;
  }

  // Format pace as MM:SS per km
  static String formatPace(double paceMinutesPerKm) {
    if (paceMinutesPerKm <= 0) return '--:--';
    
    final minutes = paceMinutesPerKm.floor();
    final seconds = ((paceMinutesPerKm - minutes) * 60).round();
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Format duration as HH:MM:SS
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Calculate calories burned (rough estimate)
  double get estimatedCalories {
    // Rough estimate: 100 calories per mile for running
    const caloriesPerMile = 100.0;
    const milesPerKm = 0.621371;
    return distance * milesPerKm * caloriesPerMile;
  }

  // Get run type based on pace
  String get runType {
    if (averagePace < 5.0) return 'Sprint';
    if (averagePace < 6.0) return 'Fast Run';
    if (averagePace < 7.5) return 'Jog';
    return 'Walk';
  }

  // Get run intensity color
  int get intensityColor {
    if (averagePace < 5.0) return 0xFFE31E24; // Red - High intensity
    if (averagePace < 6.0) return 0xFFFF9800; // Orange - Medium-high
    if (averagePace < 7.5) return 0xFF00C851; // Green - Medium
    return 0xFF2196F3; // Blue - Low intensity
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

class RunStats {
  final int totalRuns;
  final double totalDistance;
  final Duration totalTime;
  final double averagePace;
  final double longestRun;
  final double fastestPace;
  final int currentStreak;
  final int longestStreak;

  RunStats({
    required this.totalRuns,
    required this.totalDistance,
    required this.totalTime,
    required this.averagePace,
    required this.longestRun,
    required this.fastestPace,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory RunStats.fromRuns(List<Run> runs, int currentStreak, int longestStreak) {
    if (runs.isEmpty) {
      return RunStats(
        totalRuns: 0,
        totalDistance: 0,
        totalTime: Duration.zero,
        averagePace: 0,
        longestRun: 0,
        fastestPace: 0,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
      );
    }

    final totalDistance = runs.fold<double>(0, (sum, run) => sum + run.distance);
    final totalTime = runs.fold<Duration>(Duration.zero, (sum, run) => sum + run.duration);
    final averagePace = totalDistance > 0 ? (totalTime.inMinutes / totalDistance).toDouble() : 0.0;
    final longestRun = runs.map((run) => run.distance).reduce((a, b) => a > b ? a : b).toDouble();
    final fastestPace = runs.map((run) => run.averagePace).reduce((a, b) => a < b ? a : b).toDouble();

    return RunStats(
      totalRuns: runs.length,
      totalDistance: totalDistance,
      totalTime: totalTime,
      averagePace: averagePace,
      longestRun: longestRun,
      fastestPace: fastestPace,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }
} 
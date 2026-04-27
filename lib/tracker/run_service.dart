import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:geolocator/geolocator.dart';
import 'package:health/health.dart';
import 'package:trego/tracker/run_model.dart';
import 'package:trego/auth/auth_service.dart';

class RunService {
  static final RunService _instance = RunService._internal();
  factory RunService() => _instance;
  RunService._internal()
      : _positionStreamFactory = _defaultPositionStreamFactory,
        _skipPermissionChecks = false {
    // Initialize health data asynchronously to not block app startup
    Future.delayed(const Duration(milliseconds: 500), () {
      _initializeHealth();
    });
  }

  /// Test-only. Inject a position-stream factory that returns a fresh stream
  /// each call so we can simulate pause/resume without a real device.
  /// Skips Geolocator permission / service-enabled checks, which fail in
  /// the flutter_test harness.
  @visibleForTesting
  RunService.testable({
    required Stream<Position> Function() positionStreamFactory,
  })  : _positionStreamFactory = positionStreamFactory,
        _skipPermissionChecks = true;

  static RunService get instance => _instance;

  /// Injectable for tests. Defaults to Geolocator.getPositionStream.
  final Stream<Position> Function() _positionStreamFactory;

  /// When true, startRun skips the Geolocator permission / service-enabled
  /// preflight. Only set by [RunService.testable].
  final bool _skipPermissionChecks;

  static Stream<Position> _defaultPositionStreamFactory() =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      );

  // Lazy so the `testable` constructor doesn't touch Firebase at construction
  // time (Firebase.initializeApp is not called in unit tests).
  FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
  AuthService? _authServiceInstance;
  AuthService get _authService => _authServiceInstance ??= AuthService();

  // GPS tracking
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _currentRoute = [];
  DateTime? _runStartTime;
  Timer? _runTimer;
  Duration _currentDuration = Duration.zero;
  double _currentDistance = 0.0;
  LatLng? _lastPosition;
  
  // Health data
  final HealthFactory _health = HealthFactory();
  bool _isHealthAvailable = false;

  // Add pause/resume state
  bool _isPaused = false;
  DateTime? _pauseTime;
  Duration _pausedDuration = Duration.zero;

  // Stream controllers for real-time updates
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<double> _distanceController = StreamController<double>.broadcast();
  final StreamController<List<LatLng>> _routeController = StreamController<List<LatLng>>.broadcast();
  final StreamController<bool> _isRunningController = StreamController<bool>.broadcast();
  final StreamController<bool> _isPausedController = StreamController<bool>.broadcast();
  final StreamController<Object> _errorController = StreamController<Object>.broadcast();

  // Getters
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<double> get distanceStream => _distanceController.stream;
  Stream<List<LatLng>> get routeStream => _routeController.stream;
  Stream<bool> get isRunningStream => _isRunningController.stream;
  Stream<bool> get isPausedStream => _isPausedController.stream;
  /// Surfaces stream / IO errors so the Record flow can react.
  Stream<Object> get errorStream => _errorController.stream;
  bool get isRunning => _runStartTime != null;
  bool get isPaused => _isPaused;
  Duration get currentDuration => _currentDuration;
  double get currentDistance => _currentDistance;
  /// Alias for [currentDistance] in kilometers. Used by tests that want an
  /// unambiguous unit-suffixed name.
  double get currentDistanceKm => _currentDistance;
  List<LatLng> get currentRoute => List.unmodifiable(_currentRoute);

  /// Current pace in MM:SS per kilometer, or null if no meaningful pace yet
  /// (zero distance or zero duration). Computed from current duration and
  /// distance — does NOT require a finished run.
  Duration? get currentPacePerKm {
    if (_currentDistance <= 0 || _currentDuration == Duration.zero) return null;
    final secondsPerKm =
        _currentDuration.inMilliseconds / 1000.0 / _currentDistance;
    if (!secondsPerKm.isFinite || secondsPerKm <= 0) return null;
    return Duration(milliseconds: (secondsPerKm * 1000).round());
  }

  /// Most recent GPS accuracy in meters, or null if none reported yet.
  /// We don't track accuracy on the position stream today, so this is null.
  double? get currentAccuracyMeters => null;

  // Initialize health data access
  Future<void> _initializeHealth() async {
    try {
      // Check if health is available on this platform
      final types = [HealthDataType.STEPS, HealthDataType.DISTANCE_WALKING_RUNNING];
      
      _isHealthAvailable = await _health.requestAuthorization(types);
      print('Health initialization result: $_isHealthAvailable');
    } catch (e) {
      print('Health initialization error: $e');
      _isHealthAvailable = false;
      // Don't crash the app if health is not available
    }
  }

  // Start a new run
  Future<bool> startRun() async {
    try {
      // Check if already running
      if (isRunning) {
        print('Run is already in progress');
        return false;
      }

      // Check location permissions (skipped for unit tests that inject a
      // position-stream factory via [RunService.testable]).
      if (!_skipPermissionChecks) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          final requested = await Geolocator.requestPermission();
          if (requested == LocationPermission.denied) {
            print('Location permission denied');
            return false;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          print('Location permission denied forever');
          return false;
        }

        // Check if location services are enabled
        final isEnabled = await Geolocator.isLocationServiceEnabled();
        if (!isEnabled) {
          print('Location services are disabled');
          return false;
        }
      }

      // Reset run data
      _currentRoute.clear();
      _currentDistance = 0.0;
      _currentDuration = Duration.zero;
      _lastPosition = null;
      _runStartTime = DateTime.now();
      _pausedDuration = Duration.zero;
      _isPaused = false;
      _pauseTime = null;

      // Start location tracking with error handling
      try {
        _positionStream = _positionStreamFactory().listen(
          _onPositionUpdate,
          onError: (error) {
            print('Position stream error: $error');
            // Don't crash the app, just log the error
          },
        );
      } catch (e) {
        print('Error setting up position stream: $e');
        // Reset state if position stream fails
        _runStartTime = null;
        return false;
      }

      // Start timer
      _runTimer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);

      // Notify listeners
      _isRunningController.add(true);
      _durationController.add(_currentDuration);
      _distanceController.add(_currentDistance);
      _routeController.add(_currentRoute);

      return true;
    } catch (e) {
      print('Error starting run: $e');
      // Reset state on error
      _runStartTime = null;
      _currentRoute.clear();
      _currentDistance = 0.0;
      _currentDuration = Duration.zero;
      _lastPosition = null;
      return false;
    }
  }

  // Stop the current run
  Future<Run?> stopRun({String? notes}) async {
    try {
      if (!isRunning) return null;

      // Stop tracking
      await _positionStream?.cancel();
      _runTimer?.cancel();
      _positionStream = null;
      _runTimer = null;

      final endTime = DateTime.now();
      final duration = endTime.difference(_runStartTime!);
      final pace = Run.calculatePace(duration, _currentDistance);

      // Create run object. In test mode we skip AuthService entirely — it
      // touches FirebaseAuth.instance at field-init time which blows up in
      // the test harness.
      final run = Run(
        userId: _skipPermissionChecks
            ? ''
            : (_authService.currentUser?.uid ?? ''),
        startTime: _runStartTime!,
        endTime: endTime,
        duration: duration,
        distance: _currentDistance,
        averagePace: pace,
        route: List.from(_currentRoute),
        notes: notes,
      );

      // Save to Firestore (skipped in test mode — Firestore is not
      // initialized in unit tests).
      if (!_skipPermissionChecks) {
        await _saveRun(run);
      }

      // Reset state
      _runStartTime = null;
      _currentRoute.clear();
      _currentDistance = 0.0;
      _currentDuration = Duration.zero;
      _lastPosition = null;
      _pausedDuration = Duration.zero;
      _isPaused = false;
      _pauseTime = null;

      // Notify listeners
      _isRunningController.add(false);
      _durationController.add(_currentDuration);
      _distanceController.add(_currentDistance);
      _routeController.add(_currentRoute);

      return run;
    } catch (e) {
      print('Error stopping run: $e');
      return null;
    }
  }

  // Handle position updates
  void _onPositionUpdate(Position position) {
    try {
      if (!isRunning) return;

      final newPosition = LatLng(position.latitude, position.longitude);
      _currentRoute.add(newPosition);

      // Calculate distance
      if (_lastPosition != null) {
        final distance = _calculateDistance(_lastPosition!, newPosition);
        _currentDistance += distance;
      }

      _lastPosition = newPosition;

      // Notify listeners
      _distanceController.add(_currentDistance);
      _routeController.add(_currentRoute);
    } catch (e) {
      print('Error in position update: $e');
      // Don't crash the app, just log the error
    }
  }

  // Handle timer ticks
  void _onTimerTick(Timer timer) {
    try {
      if (!isRunning || _isPaused) return;

      _currentDuration = DateTime.now().difference(_runStartTime!) - _pausedDuration;
      _durationController.add(_currentDuration);
    } catch (e) {
      print('Error in timer tick: $e');
      // Don't crash the app, just log the error
    }
  }

  // Calculate distance between two points (Haversine formula)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLonRad = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Save run to Firestore
  Future<void> _saveRun(Run run) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('runs')
          .add(run.toMap());
    } catch (e) {
      print('Error saving run: $e');
    }
  }

  // Get user's runs
  Future<List<Run>> getUserRuns({int limit = 50}) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('runs')
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Run.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error loading runs: $e');
      return [];
    }
  }

  // Get run statistics
  Future<RunStats> getRunStats() async {
    try {
      final runs = await getUserRuns();
      
      // Get streak data
      final streakDoc = await _firestore
          .collection('users')
          .doc(_authService.currentUser?.uid)
          .collection('streak')
          .doc('running')
          .get();

      final currentStreak = streakDoc.data()?['count'] ?? 0;
      final longestStreak = streakDoc.data()?['longest'] ?? 0;

      return RunStats.fromRuns(runs, currentStreak, longestStreak);
    } catch (e) {
      print('Error loading run stats: $e');
      return RunStats(
        totalRuns: 0,
        totalDistance: 0,
        totalTime: Duration.zero,
        averagePace: 0,
        longestRun: 0,
        fastestPace: 0,
        currentStreak: 0,
        longestStreak: 0,
      );
    }
  }

  // Get weekly run statistics
  Future<RunStats> getWeeklyStats() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      
      final userId = _authService.currentUser?.uid;
      if (userId == null) return RunStats(
        totalRuns: 0,
        totalDistance: 0,
        totalTime: Duration.zero,
        averagePace: 0,
        longestRun: 0,
        fastestPace: 0,
        currentStreak: 0,
        longestStreak: 0,
      );

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('runs')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekDay))
          .orderBy('startTime', descending: true)
          .get();

      final weeklyRuns = querySnapshot.docs
          .map((doc) => Run.fromMap(doc.data(), doc.id))
          .toList();

      return RunStats.fromRuns(weeklyRuns, 0, 0);
    } catch (e) {
      print('Error loading weekly stats: $e');
      return RunStats(
        totalRuns: 0,
        totalDistance: 0,
        totalTime: Duration.zero,
        averagePace: 0,
        longestRun: 0,
        fastestPace: 0,
        currentStreak: 0,
        longestStreak: 0,
      );
    }
  }

  // Sync Apple Watch data (simplified - just steps for now)
  Future<List<Run>> syncAppleWatchData() async {
    if (!_isHealthAvailable) {
      print('Health is not available, skipping Apple Watch sync');
      return [];
    }

    try {
      final steps = await getTodaySteps();
      if (steps > 0) {
        // Create a simple run entry for steps
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        
        // Check if we already have a step entry for today
        final existingRun = await _checkExistingRun(startOfDay, now);
        if (existingRun == null) {
          // Estimate distance from steps (rough conversion)
          final estimatedDistance = steps * 0.0008; // Rough conversion to km
          
          final run = Run(
            userId: _authService.currentUser?.uid ?? '',
            startTime: startOfDay,
            endTime: now,
            duration: now.difference(startOfDay),
            distance: estimatedDistance,
            averagePace: 0.0,
            route: [],
            isSyncedFromWatch: true,
            additionalData: {
              'steps': steps,
              'source': 'Apple Watch',
            },
          );

          await _saveRun(run);
          return [run];
        }
      }

      return [];
    } catch (e) {
      print('Error syncing Apple Watch data: $e');
      return [];
    }
  }

  // Check if a run already exists for the given time range
  Future<Run?> _checkExistingRun(DateTime startTime, DateTime endTime) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return null;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('runs')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endTime))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Run.fromMap(querySnapshot.docs.first.data(), querySnapshot.docs.first.id);
      }

      return null;
    } catch (e) {
      print('Error checking existing run: $e');
      return null;
    }
  }

  // Get today's step count from Apple Watch
  Future<double> getTodaySteps() async {
    if (!_isHealthAvailable) {
      print('Health is not available, returning 0 steps');
      return 0;
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final steps = await _health.getHealthDataFromTypes(
        startOfDay,
        endOfDay,
        [HealthDataType.STEPS],
      );

      double totalSteps = 0;
      for (final step in steps) {
        if (step.type == HealthDataType.STEPS) {
          totalSteps += (step.value as num).toDouble();
        }
      }

      return totalSteps;
    } catch (e) {
      print('Error getting steps: $e');
      return 0;
    }
  }

  // Pause/resume.
  //
  // NOTE: StreamSubscription.pause() only BUFFERS events from the underlying
  // stream — the Geolocator keeps producing points during a "pause," so
  // distance accumulated anyway when the subscription was resumed. We now
  // cancel the subscription on pause and create a fresh one on resume via
  // the injected factory. Test coverage:
  // test/tracker/run_service_pause_test.dart.
  Future<void> pauseRun() async {
    if (!isRunning || _isPaused) return;
    _isPaused = true;
    _pauseTime = DateTime.now();
    _runTimer?.cancel();
    _runTimer = null;
    await _positionStream?.cancel(); // CANCEL — not .pause()
    _positionStream = null;
    _isPausedController.add(true); // Notify UI that run is paused
  }

  Future<void> resumeRun() async {
    if (!isRunning || !_isPaused) return;
    _isPaused = false;
    if (_pauseTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseTime!);
    }
    _pauseTime = null;
    // Fresh subscription via the injected factory.
    try {
      _positionStream = _positionStreamFactory().listen(
        _onPositionUpdate,
        onError: (error) {
          print('Position stream error: $error');
        },
      );
    } catch (e) {
      print('Error re-subscribing to position stream on resume: $e');
    }
    // Restart timer
    _runTimer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);
    _isPausedController.add(false); // Notify UI that run is resumed
  }

  // Dispose resources
  void dispose() {
    _positionStream?.cancel();
    _runTimer?.cancel();
    _durationController.close();
    _distanceController.close();
    _routeController.close();
    _isRunningController.close();
    _isPausedController.close();
    _errorController.close();
  }
}
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trego/shared/app_theme.dart';
import 'package:trego/tracker/run_service.dart';
import 'package:trego/tracker/run_model.dart';
import 'package:trego/auth/auth_service.dart';
import 'dart:async';

class LiveRunTrackerScreen extends StatefulWidget {
  const LiveRunTrackerScreen({super.key});

  @override
  State<LiveRunTrackerScreen> createState() => _LiveRunTrackerScreenState();
}

class _LiveRunTrackerScreenState extends State<LiveRunTrackerScreen>
    with TickerProviderStateMixin {
  bool _isTracking = false;
  bool _isPaused = false;
  bool _hasLocationPermission = false;
  
  // GPS tracking
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _routePoints = [];
  Position? _currentPosition;
  final AuthService _authService = AuthService();
  final RunService _runService = RunService.instance;
  
  // Run data
  DateTime? _startTime;
  DateTime? _pauseTime;
  Duration _elapsedTime = Duration.zero;
  Duration _pausedTime = Duration.zero;
  double _totalDistance = 0.0;
  double _currentPace = 0.0;
  double _averagePace = 0.0;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Timer for updating elapsed time
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkLocationPermission();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationPermissionDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationPermissionDialog();
      return;
    }

    setState(() {
      _hasLocationPermission = true;
    });
    
    // Get initial position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting initial position: $e');
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to track your run.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('This app needs location permission to track your runs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startTracking() async {
    if (!_hasLocationPermission) {
      _checkLocationPermission();
      return;
    }

    setState(() {
      _isTracking = true;
      _isPaused = false;
      _startTime = DateTime.now();
      _routePoints.clear();
      _totalDistance = 0.0;
      _currentPace = 0.0;
      _averagePace = 0.0;
      _elapsedTime = Duration.zero;
      _pausedTime = Duration.zero;
    });

    // Start timer for elapsed time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTracking && !_isPaused) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!) - _pausedTime;
        });
      }
    });

    // Start GPS tracking
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      if (_isTracking && !_isPaused) {
        _updatePosition(position);
      }
    });

    _slideController.forward();
    _pulseController.repeat(reverse: true);
    _runService.startRun();
  }

  void _pauseTracking() {
    setState(() {
      _isPaused = true;
      _pauseTime = DateTime.now();
    });
    _pulseController.stop();
    _runService.pauseRun();
  }

  void _resumeTracking() {
    setState(() {
      _isPaused = false;
      if (_pauseTime != null) {
        _pausedTime += DateTime.now().difference(_pauseTime!);
      }
    });
    _pulseController.repeat(reverse: true);
    _runService.resumeRun();
  }

  void _stopTracking() async {
    _positionStream?.cancel();
    _timer?.cancel();
    _pulseController.stop();

    if (_isTracking && _routePoints.isNotEmpty) {
      // Save run to Firestore
      final run = Run(
        userId: _authService.currentUser?.uid ?? '',
        startTime: _startTime!,
        endTime: DateTime.now(),
        duration: _elapsedTime,
        distance: _totalDistance / 1000, // Convert to kilometers
        averagePace: _averagePace,
        route: _routePoints,
      );

      try {
        await _runService.stopRun();
        if (mounted) {
          Navigator.pop(context, run);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save run: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      Navigator.pop(context);
    }
  }

  void _updatePosition(Position position) {
    final newPoint = LatLng(position.latitude, position.longitude);
    
    setState(() {
      _currentPosition = position;
      _routePoints.add(newPoint);
    });

    // Calculate distance
    if (_routePoints.length > 1) {
      final previousPoint = _routePoints[_routePoints.length - 2];
      final distance = Geolocator.distanceBetween(
        previousPoint.latitude,
        previousPoint.longitude,
        newPoint.latitude,
        newPoint.longitude,
      );
      
      setState(() {
        _totalDistance += distance;
        _currentPace = _calculatePace(_elapsedTime, _totalDistance);
        _averagePace = _calculatePace(_elapsedTime, _totalDistance);
      });
    }
  }

  double _calculatePace(Duration time, double distance) {
    if (distance == 0) return 0;
    final timeInMinutes = time.inSeconds / 60;
    final distanceInKm = distance / 1000;
    return timeInMinutes / distanceInKm; // minutes per kilometer
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.round()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)}km';
    }
  }

  String _formatPace(double pace) {
    if (pace == 0) return '--:--';
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isTracking ? 'Live Run' : 'Ready to Run',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryRed.withOpacity(0.1),
                  AppTheme.background,
                ],
              ),
            ),
          ),

          // Top Bar (remove back button here)
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(AppTheme.spacingM),
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: AppTheme.cardDecoration,
              child: Row(
                children: [
                  // Removed IconButton for back navigation
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isTracking ? 'Live Run' : 'Ready to Run',
                          style: AppTheme.titleLarge,
                        ),
                        Text(
                          _isTracking 
                              ? 'Tracking your progress...'
                              : 'Tap start to begin',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (_isTracking)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Stats Panel
          Positioned(
            top: 120,
            left: AppTheme.spacingM,
            right: AppTheme.spacingM,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  children: [
                    // Time and Distance
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.timer_rounded,
                            value: _formatDuration(_elapsedTime),
                            label: 'Time',
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.straighten_rounded,
                            value: _formatDistance(_totalDistance),
                            label: 'Distance',
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    
                    // Pace
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.speed_rounded,
                            value: _formatPace(_currentPace),
                            label: 'Current Pace',
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.trending_up_rounded,
                            value: _formatPace(_averagePace),
                            label: 'Avg Pace',
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Route Points Counter
          Positioned(
            top: 280,
            left: AppTheme.spacingM,
            right: AppTheme.spacingM,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: AppTheme.cardDecoration,
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.primaryRed,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    'GPS Points: ${_routePoints.length}',
                    style: AppTheme.bodyMedium,
                  ),
                  const Spacer(),
                  if (_currentPosition != null)
                    Text(
                      '📍 ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      style: AppTheme.caption,
                    ),
                ],
              ),
            ),
          ),

          // Control Buttons
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isTracking) ...[
                    // Pause/Resume Button
                    _buildControlButton(
                      icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: AppTheme.primaryOrange,
                      onPressed: _isPaused ? _resumeTracking : _pauseTracking,
                    ),
                    const SizedBox(width: AppTheme.spacingL),
                  ],
                  
                  // Start/Stop Button
                  _buildControlButton(
                    icon: _isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: _isTracking ? AppTheme.primaryRed : AppTheme.primaryGreen,
                    onPressed: _isTracking ? _stopTracking : _startTracking,
                    isLarge: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: AppTheme.animationMedium,
        width: isLarge ? 80 : 60,
        height: isLarge ? 80 : 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isLarge ? 32 : 24,
        ),
      ),
    );
  }
} 
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trego/tracker/run_model.dart' as run_model show Run, LatLng;
import 'package:trego/tracker/run_summary_screen.dart';
import 'package:trego/tracker/run_service.dart';
import 'package:trego/achievements/achievement_service.dart';
import 'package:trego/auth/auth_service.dart';

class RunTrackerScreen extends StatefulWidget {
  const RunTrackerScreen({super.key});

  @override
  State<RunTrackerScreen> createState() => _RunTrackerScreenState();
}

class _RunTrackerScreenState extends State<RunTrackerScreen>
    with TickerProviderStateMixin {
  final RunService _runService = RunService();
  final AchievementService _achievementService = AchievementService();
  
  Duration _currentDuration = Duration.zero;
  double _currentDistance = 0.0;
  double _currentPace = 0.0;
  bool _isRunning = false;
  bool _isLoading = false;
  
  // Map related
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  LatLng? _currentPosition;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<double>? _distanceSubscription;
  StreamSubscription<bool>? _isRunningSubscription;
  StreamSubscription<List<run_model.LatLng>>? _routeSubscription;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Initialize run service and listen to streams
    _initializeRunService();
    _getCurrentLocation();
  }

  void _initializeRunService() {
    try {
      // Listen to run service streams
      _durationSubscription = _runService.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _currentDuration = duration;
            _updatePace();
          });
        }
      }, onError: (error) {
        print('Duration stream error: $error');
      });
      
      _distanceSubscription = _runService.distanceStream.listen((distance) {
        if (mounted) {
          setState(() {
            _currentDistance = distance;
            _updatePace();
          });
        }
      }, onError: (error) {
        print('Distance stream error: $error');
      });
      
      _isRunningSubscription = _runService.isRunningStream.listen((isRunning) {
        if (mounted) {
          setState(() {
            _isRunning = isRunning;
          });
          
          if (isRunning) {
            _pulseController.repeat(reverse: true);
            _slideController.forward();
          } else {
            _pulseController.stop();
            _pulseController.reset();
          }
        }
      }, onError: (error) {
        print('IsRunning stream error: $error');
      });

      _routeSubscription = _runService.routeStream.listen((route) {
        if (mounted) {
          setState(() {
            _routePoints = route.map((point) => 
              LatLng(point.latitude, point.longitude)
            ).toList();
            _updateMapRoute();
          });
        }
      }, onError: (error) {
        print('Route stream error: $error');
      });
    } catch (e) {
      print('Error initializing run service: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _updatePace() {
    if (_currentDistance > 0 && _currentDuration.inMinutes > 0) {
      setState(() {
        _currentPace = _currentDuration.inMinutes / _currentDistance;
      });
    }
  }

  void _updateMapRoute() {
    if (_routePoints.isNotEmpty) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('run_route'),
            points: _routePoints.map((point) => 
              LatLng(point.latitude, point.longitude)
            ).toList(),
            color: const Color(0xFFE31E24),
            width: 4,
          ),
        };
        
        // Update current position marker
        if (_routePoints.isNotEmpty) {
          final lastPoint = _routePoints.last;
          _markers = {
            Marker(
              markerId: const MarkerId('current_position'),
              position: LatLng(lastPoint.latitude, lastPoint.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: const InfoWindow(title: 'Current Position'),
            ),
          };
        }
      });
    }
  }

  @override
  void dispose() {
    try {
      _durationSubscription?.cancel();
      _distanceSubscription?.cancel();
      _isRunningSubscription?.cancel();
      _routeSubscription?.cancel();
      _pulseController.dispose();
      _slideController.dispose();
      _runService.dispose();
    } catch (e) {
      print('Error in dispose: $e');
    }
    super.dispose();
  }

  Future<void> _startRun() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _runService.startRun();
      if (success) {
        // Check for achievements
        final userId = AuthService().currentUser?.uid;
        if (userId != null) {
          try {
            await _achievementService.checkAndAwardAchievements(userId);
          } catch (e) {
            print('Achievement check error: $e');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to start run. Please check location permissions and ensure location services are enabled.'),
              backgroundColor: Color(0xFFE31E24),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error starting run: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting run: ${e.toString()}'),
            backgroundColor: const Color(0xFFE31E24),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _stopRun() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final run = await _runService.stopRun();
      
      if (mounted && run != null) {
        // Navigate to run summary screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RunSummaryScreen(run: run),
          ),
        );
      }
    } catch (e) {
      print('Error stopping run: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error stopping run. Please try again.'),
            backgroundColor: Color(0xFFE31E24),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatPace() {
    if (_currentPace <= 0) return '--:--';
    
    final minutes = _currentPace.floor();
    final seconds = ((_currentPace - minutes) * 60).round();
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? const LatLng(37.7749, -122.4194),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),
          
          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  if (_isRunning)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE31E24),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Stats Overlay
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Timer
                    Text(
                      _formatDuration(_currentDuration),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            icon: '📏',
                            value: '${_currentDistance.toStringAsFixed(2)}',
                            label: 'Distance (km)',
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            icon: '⚡',
                            value: _formatPace(),
                            label: 'Pace /km',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Start/Stop Button
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRunning ? _pulseAnimation.value : 1.0,
                  child: SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : (_isRunning ? _stopRun : _startRun),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRunning ? const Color(0xFFE31E24) : const Color(0xFF00C851),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: (_isRunning ? const Color(0xFFE31E24) : const Color(0xFF00C851)).withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isRunning ? 'Stop Run' : 'Start Run',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trego/tracker/run_model.dart' as run_model;
import 'package:trego/tracker/run_service.dart';
import 'package:trego/achievements/achievement_service.dart';
import 'package:trego/auth/auth_service.dart';

class RunSummaryScreen extends StatefulWidget {
  final run_model.Run run;

  const RunSummaryScreen({super.key, required this.run});

  @override
  State<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends State<RunSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _initializeMap();
    
    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  void _initializeMap() {
    if (widget.run.route.isNotEmpty) {
      final routePoints = widget.run.route.map((point) => 
        LatLng(point.latitude, point.longitude)
      ).toList();
      
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('run_route'),
            points: routePoints,
            color: const Color(0xFFE31E24),
            width: 4,
          ),
        };
        
        // Add start and end markers
        _markers = {
          Marker(
            markerId: const MarkerId('start'),
            position: routePoints.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Start'),
          ),
          Marker(
            markerId: const MarkerId('end'),
            position: routePoints.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'End'),
          ),
        };
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _shareRun() async {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: Color(0xFFE31E24),
      ),
    );
  }

  Future<void> _saveRun() async {
    // Run is already saved when stopped
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Run already saved!'),
        backgroundColor: Color(0xFF00C851),
      ),
    );
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
              target: widget.run.route.isNotEmpty 
                ? LatLng(widget.run.route.first.latitude, widget.run.route.first.longitude)
                : const LatLng(37.7749, -122.4194),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
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
                      icon: const Icon(Icons.share_rounded),
                      onPressed: _shareRun,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Stats Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 20,
                      offset: Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      'Run Complete! 🎉',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: '📏',
                            value: '${widget.run.distance.toStringAsFixed(2)}',
                            label: 'Distance (km)',
                            color: const Color(0xFFE31E24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: '⏱️',
                            value: run_model.Run.formatDuration(widget.run.duration),
                            label: 'Duration',
                            color: const Color(0xFF00C851),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: '⚡',
                            value: run_model.Run.formatPace(widget.run.averagePace),
                            label: 'Avg Pace /km',
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: '🔥',
                            value: '${widget.run.estimatedCalories.round()}',
                            label: 'Calories',
                            color: const Color(0xFF9C27B0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveRun,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE31E24),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Save Run',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE31E24),
                              side: const BorderSide(color: Color(0xFFE31E24)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
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
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
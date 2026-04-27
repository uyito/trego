import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../shared/theme/context_tokens.dart';

typedef RouteMapBuilderOverride = Widget Function(
  List<LatLng> polyline,
  LatLng? currentPosition,
  bool autoFollow,
  bool showStartEndPins,
);

class RouteMap extends StatefulWidget {
  final List<LatLng> polyline;
  final LatLng? currentPosition;
  final bool autoFollow;
  final bool showStartEndPins;
  final VoidCallback? onTap;

  const RouteMap({
    super.key,
    required this.polyline,
    this.currentPosition,
    this.autoFollow = true,
    this.showStartEndPins = false,
    this.onTap,
  });

  /// Test-only hook. When non-null, [RouteMap] renders whatever this returns
  /// instead of a real GoogleMap. Used because PlatformView doesn't render
  /// in Flutter widget tests.
  static RouteMapBuilderOverride? builderOverride;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  GoogleMapController? _controller;
  String? _darkStyleJson;
  DateTime _lastCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/map_styles/dark.json').then((s) {
      if (mounted) setState(() => _darkStyleJson = s);
    });
  }

  @override
  void didUpdateWidget(covariant RouteMap old) {
    super.didUpdateWidget(old);
    if (widget.autoFollow &&
        widget.currentPosition != null &&
        _controller != null) {
      final now = DateTime.now();
      if (now.difference(_lastCameraUpdate) >= const Duration(milliseconds: 500)) {
        _lastCameraUpdate = now;
        _controller!.animateCamera(
          CameraUpdate.newLatLng(widget.currentPosition!),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (RouteMap.builderOverride != null) {
      return RouteMap.builderOverride!(
        widget.polyline,
        widget.currentPosition,
        widget.autoFollow,
        widget.showStartEndPins,
      );
    }
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: widget.polyline,
      width: 4,
      color: tokens.brand,
      geodesic: true,
    );

    final markers = <Marker>{};
    if (widget.showStartEndPins && widget.polyline.length >= 2) {
      markers.add(Marker(
        markerId: const MarkerId('start'),
        position: widget.polyline.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
      markers.add(Marker(
        markerId: const MarkerId('end'),
        position: widget.polyline.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.currentPosition ??
              (widget.polyline.isNotEmpty ? widget.polyline.first : const LatLng(0, 0)),
          zoom: 16,
        ),
        polylines: {polyline},
        markers: markers,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
        onMapCreated: (c) {
          _controller = c;
          if (isDark && _darkStyleJson != null) {
            c.setMapStyle(_darkStyleJson);
          }
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:provider/provider.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../../tracker/record_state.dart';
import '../../tracker/run_model.dart' as run_model;
import '../../tracker/session_controller.dart';
import '../../widgets/core/gps_status_indicator.dart';
import '../../widgets/core/route_map.dart';

class LiveRecordScreen extends StatelessWidget {
  const LiveRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SessionController>();
    final tokens = context.tokens;
    final isPaused = c.state == RecordState.paused;

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: SafeArea(
        child: Column(children: [
          // Top bar: status + GPS indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
            child: Row(children: [
              Text(
                isPaused ? 'Paused' : 'Recording',
                style: context.typo.label.copyWith(color: tokens.inkMuted),
              ),
              const Spacer(),
              GpsStatusIndicator(
                status: _gpsStatus(c.currentAccuracyMeters),
                accuracyMeters: c.currentAccuracyMeters,
              ),
            ]),
          ),
          // Map (top half)
          Expanded(
            flex: 1,
            child: RouteMap(
              polyline: _toGmap(c.route),
              currentPosition: c.route.isNotEmpty ? _toGmapPoint(c.route.last) : null,
              autoFollow: !isPaused,
            ),
          ),
          // Auto-pause banner (sits just above the stats area)
          if (isPaused && c.pauseReason == PauseReason.auto)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: Space.sm, horizontal: Space.md),
              color: tokens.surface,
              child: Text(
                "Auto-paused — we'll resume when you move",
                textAlign: TextAlign.center,
                style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
              ),
            ),
          // Stats grid (bottom half)
          Expanded(
            flex: 1,
            child: Container(
              color: tokens.surfaceSunken,
              padding: const EdgeInsets.all(Space.md),
              child: Column(children: [
                Expanded(
                  child: Row(children: [
                    _StatCard(
                        value: run_model.Run.formatDuration(c.elapsed),
                        label: 'Time'),
                    const SizedBox(width: Space.sm),
                    _StatCard(value: c.distanceKm.toStringAsFixed(2), label: 'km'),
                  ]),
                ),
                const SizedBox(height: Space.sm),
                Expanded(
                  child: Row(children: [
                    _StatCard(
                      value: c.currentPacePerKm == null
                          ? '—'
                          : run_model.Run.formatDuration(c.currentPacePerKm!),
                      label: '/km pace',
                    ),
                    const SizedBox(width: Space.sm),
                    _StatCard(value: _kcal(c).toString(), label: 'kcal'),
                  ]),
                ),
                const SizedBox(height: Space.md),
                Row(children: [
                  Expanded(
                    child: _ControlButton(
                      label: isPaused ? '▶ RESUME' : '⏸ PAUSE',
                      onPressed: isPaused ? c.resume : c.pauseManual,
                      primary: isPaused,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: _ControlButton(
                      label: '⏹ STOP',
                      onPressed: c.requestStop,
                      destructive: true,
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  static List<gmap.LatLng> _toGmap(List<run_model.LatLng> pts) =>
      pts.map(_toGmapPoint).toList(growable: false);

  static gmap.LatLng _toGmapPoint(run_model.LatLng p) =>
      gmap.LatLng(p.latitude, p.longitude);

  static GpsStatus _gpsStatus(double? m) {
    if (m == null) return GpsStatus.acquiring;
    if (m > 30) return GpsStatus.weak;
    return GpsStatus.ready;
  }

  // Rough kcal estimate: 1 kcal per kg per km, default 70 kg.
  static int _kcal(SessionController c) => (c.distanceKm * 70).round();
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border),
          borderRadius: BorderRadius.circular(Radii.statTile),
        ),
        padding: const EdgeInsets.all(Space.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: context.typo.stat),
            const SizedBox(height: 2),
            Text(label.toUpperCase(),
                style: context.typo.label.copyWith(color: tokens.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool destructive;
  const _ControlButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bg = destructive
        ? tokens.brand
        : (primary ? tokens.brand : tokens.surface);
    final fg = destructive || primary ? tokens.onBrand : tokens.ink;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(Radii.standardCard),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: destructive || primary ? null : Border.all(color: tokens.border),
          borderRadius: BorderRadius.circular(Radii.standardCard),
        ),
        padding: const EdgeInsets.symmetric(vertical: Space.md),
        alignment: Alignment.center,
        child: Text(label, style: context.typo.button.copyWith(color: fg)),
      ),
    );
  }
}

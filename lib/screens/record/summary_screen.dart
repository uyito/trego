import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../metrics/metrics_models.dart';
import '../../metrics/metrics_provider.dart';
import '../../metrics/widgets/pr_hero_banner.dart';
import '../../metrics/widgets/weekly_progress_card.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../../tracker/record_errors.dart';
import '../../tracker/run_model.dart' as run_model;
import '../../tracker/session_controller.dart';
import '../../widgets/core/big_stat.dart';
import '../../widgets/core/route_map.dart';
import '../../widgets/core/split_row.dart';
import 'summary_share_text.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SessionController>();
    final mp = context.watch<MetricsProvider>();
    final run = c.lastRun;
    final tokens = context.tokens;

    if (run == null) {
      // Defensive — should not happen in the real flow.
      return Scaffold(
        backgroundColor: tokens.canvas,
        body: const Center(child: Text('No run data.')),
      );
    }

    final title = autoRunTitle(run.startTime);
    final distanceStr = run.distance.toStringAsFixed(2);
    final durationStr = run_model.Run.formatDuration(run.duration);
    final paceStr = formatPace(run.averagePace);

    final snap = mp.snapshot;
    final prevSnap = mp.previousSnapshot;
    final previousWeek = snap == null || snap.history.isEmpty ? null : snap.history.last;

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: CustomScrollView(slivers: [
        // PR banner — top-most when applicable.
        SliverToBoxAdapter(
          child: PrHeroBanner(
            prs: snap?.prs,
            previousPrs: prevSnap?.prs,
            runId: run.id,
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + Space.md,
              left: Space.lg,
              right: Space.lg,
              bottom: Space.lg,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tokens.brandContainerStart, tokens.brandContainerEnd],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: tokens.onBrand,
                    onPressed: () => c.exitSummary(),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _shareRun(
                      run: run,
                      title: title,
                      prs: snap?.prs,
                      previousPrs: prevSnap?.prs,
                    ),
                    child: Text(
                      'SHARE',
                      style: context.typo.button.copyWith(color: tokens.onBrand),
                    ),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_dateLabel(run.startTime),
                          style: context.typo.label.copyWith(
                            color: tokens.onBrand.withValues(alpha: 0.9),
                          )),
                      const SizedBox(height: 4),
                      Text(title,
                          style: context.typo.display.copyWith(color: tokens.onBrand)),
                      const SizedBox(height: 2),
                      Text('Tap to rename',
                          style: context.typo.bodySmall.copyWith(
                            color: tokens.onBrand.withValues(alpha: 0.85),
                          )),
                      const SizedBox(height: Space.lg),
                      Row(children: [
                        Expanded(
                          child: BigStat(
                              value: distanceStr,
                              label: 'km',
                              size: BigStatSize.l,
                              color: tokens.onBrand),
                        ),
                        Expanded(
                          child: BigStat(
                              value: durationStr,
                              label: 'Time',
                              size: BigStatSize.l,
                              color: tokens.onBrand),
                        ),
                        Expanded(
                          child: BigStat(
                              value: paceStr,
                              label: '/km',
                              size: BigStatSize.l,
                              color: tokens.onBrand),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (c.offlineQueued)
          SliverToBoxAdapter(
            child: Container(
              color: tokens.surface,
              padding: const EdgeInsets.all(Space.md),
              child: Text(RecordErrorsCopy.offlineBanner,
                  style: context.typo.bodySmall.copyWith(color: tokens.inkMuted)),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.standardCard),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: RouteMap(
                  polyline: run.route.map(_toGmap).toList(),
                  autoFollow: false,
                  showStartEndPins: true,
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('SPLITS',
                  style: context.typo.label.copyWith(color: tokens.inkMuted)),
              const SizedBox(height: Space.sm),
              ..._buildSplits(run, context),
              const SizedBox(height: Space.lg),
            ]),
          ),
        ),
        // Weekly progress card — bottom of the summary.
        if (snap != null)
          SliverToBoxAdapter(
            child: WeeklyProgressCard(
              thisWeek: snap.thisWeek,
              previousWeek: previousWeek,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
      ]),
    );
  }

  /// Convert internal run-model LatLng to google_maps_flutter LatLng.
  static gmap.LatLng _toGmap(run_model.LatLng p) => gmap.LatLng(p.latitude, p.longitude);

  List<Widget> _buildSplits(run_model.Run run, BuildContext context) {
    if (run.distance < 1.0) return [];
    // Compute per-km splits assuming even pace across route points.
    // Real implementation would slice the route by km boundaries; for
    // MVP we fabricate N kilometers of the average pace.
    final n = run.distance.floor();
    final secondsPerKm = run.averagePace * 60;
    return List.generate(n, (i) {
      return SplitRow(
        kmIndex: i + 1,
        splitPace: Duration(seconds: secondsPerKm.round()),
        fastestPaceSecPerKm: secondsPerKm,
        slowestPaceSecPerKm: secondsPerKm,
      );
    });
  }

  static String _dateLabel(DateTime d) {
    final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return 'Today · $h:$m $ampm';
  }

  void _shareRun({
    required run_model.Run run,
    required String title,
    required Prs? prs,
    required Prs? previousPrs,
  }) {
    final text = buildShareText(
      run: run,
      prs: prs,
      previousPrs: previousPrs,
    );
    Share.share(text, subject: title);
  }
}

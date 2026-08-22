import 'package:flutter/material.dart';
import '../analytics/advanced_analytics_dashboard.dart';
import '../shared/theme/context_tokens.dart';
import '../tracker/tracker_dashboard_screen.dart';
import '../widgets/core/trego_app_bar.dart';
import '../widgets/core/trego_scaffold.dart';

/// Progress detail screen, reached from Home's "This Week" section.
///
/// Two tabs over the existing (unrestyled) legacy screens:
/// Run History = [TrackerDashboardScreen], Analytics = [AdvancedAnalyticsDashboard].
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DefaultTabController(
      length: 2,
      child: TregoScaffold(
        appBar: const TregoAppBar(title: 'Progress'),
        body: Column(
          children: [
            Material(
              color: tokens.surfaceSunken,
              child: TabBar(
                labelColor: tokens.brand,
                unselectedLabelColor: tokens.inkMuted,
                indicatorColor: tokens.brand,
                tabs: const [
                  Tab(text: 'Run History'),
                  Tab(text: 'Analytics'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  TrackerDashboardScreen(),
                  AdvancedAnalyticsDashboard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

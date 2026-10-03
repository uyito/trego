import 'package:flutter/material.dart';

import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../../widgets/core/section_head.dart';
import '../../widgets/core/trego_app_bar.dart';
import '../../widgets/core/trego_scaffold.dart';
import 'activity_library.dart';
import 'log_activity_screen.dart';
import 'workout_service.dart';

/// Browse activities grouped by category; tapping one opens the log form.
class ActivityPickerScreen extends StatelessWidget {
  final WorkoutService? service;

  /// When true the picker is hosted inside another screen (e.g. a tab in
  /// WorkoutHub) and renders without its own app bar.
  final bool embedded;

  const ActivityPickerScreen({super.key, this.service, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return TregoScaffold(
      appBar: embedded ? null : const TregoAppBar(title: 'Log Activity'),
      body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final c in activityCategories()) ...[
                SectionHead(label: c),
                for (final a in activitiesInCategory(c))
                  ListTile(
                    key: Key('activity-${a.id}'),
                    title: Text(a.name, style: typo.body),
                    trailing: Icon(Icons.chevron_right, color: tokens.inkFaint),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LogActivityScreen(activity: a, service: service),
                      ),
                    ),
                  ),
              ],
            ],
          )),
    );
  }
}

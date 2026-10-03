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

  const ActivityPickerScreen({super.key, this.service});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return TregoScaffold(
      appBar: const TregoAppBar(title: 'Log activity'),
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

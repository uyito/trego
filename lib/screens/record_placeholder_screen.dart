import 'package:flutter/material.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../widgets/core/trego_app_bar.dart';
import '../widgets/core/trego_scaffold.dart';
import '../widgets/core/trego_button.dart';
import '../tracker/tracker_hub.dart';

class RecordPlaceholderScreen extends StatelessWidget {
  const RecordPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TregoScaffold(
      appBar: TregoAppBar(
        title: 'Record',
        trailing: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline, size: 64, color: tokens.brand),
              const SizedBox(height: Space.md),
              Text('Record flow coming soon', style: context.typo.title),
              const SizedBox(height: Space.sm),
              Text(
                'New GPS tracker lands in a later release.',
                style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
              ),
              const SizedBox(height: Space.xl),
              TregoButton(
                label: 'Open legacy tracker',
                variant: TregoButtonVariant.primary,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const TrackerHub()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

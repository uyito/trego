import 'package:flutter/material.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../widgets/core/trego_app_bar.dart';
import '../widgets/core/trego_scaffold.dart';
import '../widgets/core/trego_button.dart';
import '../social/social_hub.dart';

class FeedPlaceholderScreen extends StatelessWidget {
  const FeedPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TregoScaffold(
      appBar: const TregoAppBar(title: 'Feed'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: tokens.inkMuted),
              const SizedBox(height: Space.md),
              Text('Feed coming soon', style: context.typo.title),
              const SizedBox(height: Space.sm),
              Text(
                'Activity from friends will appear here.',
                style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
              ),
              const SizedBox(height: Space.xl),
              TregoButton(
                label: 'Open legacy social hub',
                variant: TregoButtonVariant.secondary,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SocialHub()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

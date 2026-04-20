import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';

class WorkoutHeroCard extends StatelessWidget {
  final String todayLabel;
  final String title;
  final String metaLine;
  final String ctaLabel;
  final VoidCallback onStart;
  final bool isEmpty;

  const WorkoutHeroCard({
    super.key,
    required this.todayLabel,
    required this.title,
    required this.metaLine,
    required this.ctaLabel,
    required this.onStart,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.brandContainerStart, tokens.brandContainerEnd],
        ),
        borderRadius: BorderRadius.circular(Radii.standardCard),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? const [BoxShadow(color: Color(0x33C5181E), blurRadius: 18, offset: Offset(0, 8))] // ALLOW-HEX: brand color with fixed 20% alpha for const shadow
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            todayLabel.toUpperCase(),
            style: typo.label.copyWith(color: tokens.onBrand.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 6),
          Text(title, style: typo.title.copyWith(color: tokens.onBrand)),
          const SizedBox(height: 4),
          Text(
            metaLine,
            style: typo.bodySmall.copyWith(color: tokens.onBrand.withValues(alpha: 0.92)),
          ),
          const SizedBox(height: Space.md),
          Material(
            // Semantic: "the color that reads on top of brand". Renders white
            // today; tracks the token if the brand gradient is ever reversed.
            color: tokens.onBrand,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onStart,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 44, // HIG minimum tap-target height
                child: Center(
                  child: Text(
                    ctaLabel,
                    style: typo.button.copyWith(color: tokens.brand),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

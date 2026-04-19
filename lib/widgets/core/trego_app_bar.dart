import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';

class TregoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? greeting;
  final String? subtitle;
  final List<Widget>? trailing;

  const TregoAppBar({
    super.key,
    this.title,
    this.greeting,
    this.subtitle,
    this.trailing,
  }) : assert(
          (title == null) != (greeting == null),
          'Provide exactly one of title OR greeting',
        );

  @override
  Size get preferredSize => Size.fromHeight(greeting != null ? 72 : 56);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: tokens.surfaceSunken,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Row(
              children: [
                Expanded(child: _buildLeading(context)),
                if (trailing != null)
                  Row(mainAxisSize: MainAxisSize.min, children: trailing!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (title != null) {
      return Text(title!, style: context.typo.title);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(greeting!, style: context.typo.display.copyWith(fontSize: 22)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: context.typo.bodySmall.copyWith(color: context.tokens.inkMuted)),
        ],
      ],
    );
  }
}

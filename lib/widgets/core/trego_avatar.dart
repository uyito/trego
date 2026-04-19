import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';

enum TregoAvatarSize { sm, md, lg }

class TregoAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final TregoAvatarSize size;

  const TregoAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = TregoAvatarSize.md,
  });

  double get _diameter => switch (size) {
    TregoAvatarSize.sm => 24,
    TregoAvatarSize.md => 34,
    TregoAvatarSize.lg => 48,
  };

  double get _fontSize => switch (size) {
    TregoAvatarSize.sm => 10,
    TregoAvatarSize.md => 13,
    TregoAvatarSize.lg => 18,
  };

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      label: name,
      container: true,
      excludeSemantics: true,
      child: Container(
        width: _diameter,
        height: _diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tokens.brand,
          image: imageUrl != null
              ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
              : null,
        ),
        alignment: Alignment.center,
        child: imageUrl == null
            ? Text(
                _initials,
                style: context.typo.titleSmall.copyWith(
                  color: tokens.onBrand,
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
    );
  }
}

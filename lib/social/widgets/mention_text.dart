import 'package:flutter/material.dart';

/// Safely coerce a post/comment's `mentions` JSON (a `List<dynamic>` of maps)
/// into a typed list.
List<Map<String, dynamic>> mentionsOf(Map<String, dynamic> item) {
  final raw = item['mentions'];
  if (raw is List) {
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
  return const [];
}

/// Renders post/comment text with resolved `@username` mentions highlighted
/// (primary color + semibold). Only handles present in [mentions] are
/// highlighted — unresolved `@text` stays plain, so we never falsely link a
/// non-user. Non-tappable in v1.
///
/// [mentions] is the backend-provided list of `{uid, username}` maps.
class MentionText extends StatelessWidget {
  final String content;
  final List<Map<String, dynamic>> mentions;
  final TextStyle? style;

  const MentionText({
    super.key,
    required this.content,
    required this.mentions,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    if (mentions.isEmpty || content.isEmpty) {
      return Text(content, style: baseStyle);
    }

    final usernames = <String>{
      for (final m in mentions)
        if (m['username'] is String) (m['username'] as String).toLowerCase(),
    }..removeWhere((u) => u.isEmpty);

    if (usernames.isEmpty) {
      return Text(content, style: baseStyle);
    }

    final highlight = baseStyle.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    final spans = <TextSpan>[];
    final matches = _mentionMatches(content, usernames);
    var cursor = 0;
    for (final (start, end) in matches) {
      if (start > cursor) {
        spans.add(TextSpan(text: content.substring(cursor, start), style: baseStyle));
      }
      spans.add(TextSpan(text: content.substring(start, end), style: highlight));
      cursor = end;
    }
    if (cursor < content.length) {
      spans.add(TextSpan(text: content.substring(cursor), style: baseStyle));
    }

    return Text.rich(TextSpan(children: spans));
  }

  /// Finds `@handle` ranges in [content] whose lowercased handle is in
  /// [usernames]. Mirrors the backend's boundary rule (`@` not preceded by a
  /// word char) so emails/mid-word `@` aren't highlighted.
  List<(int, int)> _mentionMatches(String content, Set<String> usernames) {
    final regex = RegExp(r'(?<![A-Za-z0-9_])@([A-Za-z0-9_]{3,20})');
    final result = <(int, int)>[];
    for (final match in regex.allMatches(content)) {
      final handle = match.group(1)!.toLowerCase();
      if (usernames.contains(handle)) {
        result.add((match.start, match.end));
      }
    }
    return result;
  }
}

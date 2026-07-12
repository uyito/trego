import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/social/widgets/mention_text.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Pulls every TextSpan (with text) out of a Text.rich, paired with its color.
List<(String, Color?)> _spans(WidgetTester tester) {
  final richText = tester.widget<RichText>(find.byType(RichText).first);
  final out = <(String, Color?)>[];
  void visit(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text != null) out.add((span.text!, span.style?.color));
      for (final c in span.children ?? const <InlineSpan>[]) {
        visit(c);
      }
    }
  }

  visit(richText.text);
  return out;
}

void main() {
  group('mentionsOf', () {
    test('coerces a JSON list of maps', () {
      final result = mentionsOf({
        'mentions': [
          {'uid': 'u1', 'username': 'bob'},
        ],
      });
      expect(result, hasLength(1));
      expect(result.first['username'], 'bob');
    });

    test('empty when missing or not a list', () {
      expect(mentionsOf({}), isEmpty);
      expect(mentionsOf({'mentions': 'nope'}), isEmpty);
    });
  });

  testWidgets('renders plain Text when there are no mentions', (tester) async {
    await tester.pumpWidget(_wrap(
      const MentionText(content: 'no mentions here', mentions: []),
    ));
    expect(find.text('no mentions here'), findsOneWidget);
    expect(find.byType(RichText), findsWidgets); // (Text builds a RichText too)
  });

  testWidgets('highlights a resolved @handle in primary color', (tester) async {
    await tester.pumpWidget(_wrap(
      MentionText(
        content: 'great run @bob!',
        mentions: const [
          {'uid': 'u1', 'username': 'bob'},
        ],
      ),
    ));

    final primary = Theme.of(tester.element(find.byType(MentionText))).colorScheme.primary;
    final spans = _spans(tester);
    final mentionSpan = spans.firstWhere((s) => s.$1 == '@bob');
    expect(mentionSpan.$2, primary);
    // The surrounding text is not highlighted.
    expect(spans.any((s) => s.$1.contains('great run') && s.$2 != primary), isTrue);
  });

  testWidgets('does not highlight an unresolved @handle', (tester) async {
    await tester.pumpWidget(_wrap(
      MentionText(
        content: 'who is @ghost',
        mentions: const [
          {'uid': 'u1', 'username': 'bob'},
        ],
      ),
    ));

    final primary = Theme.of(tester.element(find.byType(MentionText))).colorScheme.primary;
    // @ghost is not in the mentions list → rendered plain, so no primary-colored span.
    expect(_spans(tester).any((s) => s.$2 == primary), isFalse);
  });

  testWidgets('does not treat an email as a mention', (tester) async {
    await tester.pumpWidget(_wrap(
      MentionText(
        content: 'mail foo@bob.com',
        mentions: const [
          {'uid': 'u1', 'username': 'bob'},
        ],
      ),
    ));
    final primary = Theme.of(tester.element(find.byType(MentionText))).colorScheme.primary;
    expect(_spans(tester).any((s) => s.$2 == primary), isFalse);
  });
}

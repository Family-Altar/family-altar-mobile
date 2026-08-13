import 'package:family_altar/screens/reader/domain/text_highlight.dart';
import 'package:family_altar/screens/reader/widgets/highlightable_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseStyle = TextStyle(fontSize: 16);
  const highlightColor = Colors.yellow;

  List<InlineSpan> build(
    String text,
    List<TextHighlight> highlights, {
    List<TapGestureRecognizer>? sink,
  }) {
    return buildHighlightSpans(
      text: text,
      highlights: highlights,
      baseStyle: baseStyle,
      resolveColor: (_) => highlightColor,
      onHighlightTapDown: (_, _) {},
      recognizerSink: sink ?? [],
    );
  }

  TextSpan span(InlineSpan s) => s as TextSpan;

  group('buildHighlightSpans', () {
    test('no highlights returns a single plain span', () {
      final spans = build('Hello world', const []);

      expect(spans, hasLength(1));
      expect(span(spans[0]).text, 'Hello world');
      expect(span(spans[0]).style, baseStyle);
      expect(span(spans[0]).recognizer, isNull);
    });

    test('highlight in the middle splits into a plain and a highlighted '
        'span', () {
      final spans = build('Hello world', const [
        TextHighlight(start: 6, end: 11, colorId: 'yellow'),
      ]);

      expect(spans, hasLength(2));
      expect(span(spans[0]).text, 'Hello ');
      expect(span(spans[1]).text, 'world');
      expect(span(spans[1]).style?.backgroundColor, highlightColor);
    });

    test('highlight fully inside the string produces three spans', () {
      final spans = build('Hello world today', const [
        TextHighlight(start: 6, end: 11, colorId: 'yellow'),
      ]);

      expect(spans, hasLength(3));
      expect(span(spans[0]).text, 'Hello ');
      expect(span(spans[1]).text, 'world');
      expect(span(spans[1]).style?.backgroundColor, highlightColor);
      expect(span(spans[2]).text, ' today');
    });

    test('highlight touching the start has no leading plain span', () {
      final spans = build('Hello world', const [
        TextHighlight(start: 0, end: 5, colorId: 'yellow'),
      ]);

      expect(span(spans[0]).text, 'Hello');
      expect(span(spans[0]).style?.backgroundColor, highlightColor);
    });

    test('highlight touching the end has no trailing plain span', () {
      final spans = build('Hello world', const [
        TextHighlight(start: 6, end: 11, colorId: 'yellow'),
      ]);
      final texts = spans.map((s) => span(s).text).toList();

      expect(texts, ['Hello ', 'world']);
    });

    test('adjacent highlights produce no gap span between them', () {
      final spans = build('Hello world', const [
        TextHighlight(start: 0, end: 5, colorId: 'yellow'),
        TextHighlight(start: 5, end: 11, colorId: 'green'),
      ]);
      final texts = spans.map((s) => span(s).text).toList();

      expect(texts, ['Hello', ' world']);
    });

    test('out-of-range offsets are clamped instead of throwing', () {
      expect(
        () => build('Hi', const [
          TextHighlight(start: -5, end: 100, colorId: 'yellow'),
        ]),
        returnsNormally,
      );

      final spans = build('Hi', const [
        TextHighlight(start: -5, end: 100, colorId: 'yellow'),
      ]);
      expect(span(spans.first).text, 'Hi');
    });

    test('a highlight starting before the previous one ended is skipped', () {
      final spans = build('Hello world', const [
        TextHighlight(start: 0, end: 8, colorId: 'yellow'),
        TextHighlight(start: 2, end: 5, colorId: 'green'),
      ]);
      final texts = spans.map((s) => span(s).text).toList();

      expect(texts, ['Hello wo', 'rld']);
    });

    test('one recognizer is created per highlighted span', () {
      final sink = <TapGestureRecognizer>[];
      build('Hello world', const [
        TextHighlight(start: 0, end: 5, colorId: 'yellow'),
        TextHighlight(start: 6, end: 11, colorId: 'green'),
      ], sink: sink);

      expect(sink, hasLength(2));
    });
  });
}

import 'package:family_altar/screens/reader/domain/text_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextHighlight', () {
    test('toJson/fromJson round trip', () {
      const highlight = TextHighlight(start: 3, end: 10, colorId: 'green');

      final json = highlight.toJson();
      final decoded = TextHighlight.fromJson(json);

      expect(decoded, highlight);
    });

    test('toJson/fromJson round trip with snippet and note', () {
      const highlight = TextHighlight(
        start: 3,
        end: 10,
        colorId: 'green',
        snippet: 'example',
        note: 'remember this',
      );

      final json = highlight.toJson();
      final decoded = TextHighlight.fromJson(json);

      expect(decoded, highlight);
    });

    test('toJson omits note when null', () {
      const highlight = TextHighlight(
        start: 0,
        end: 4,
        colorId: 'blue',
        snippet: 'abcd',
      );

      expect(highlight.toJson().containsKey('n'), isFalse);
    });

    test('fromJson defaults snippet and note when absent', () {
      final decoded = TextHighlight.fromJson(const {
        's': 1,
        'e': 2,
        'c': 'yellow',
      });

      expect(decoded.snippet, '');
      expect(decoded.note, isNull);
    });

    test('overlaps detects intersecting ranges', () {
      const highlight = TextHighlight(start: 5, end: 10, colorId: 'yellow');

      expect(highlight.overlaps(0, 6), isTrue);
      expect(highlight.overlaps(9, 15), isTrue);
      expect(highlight.overlaps(6, 8), isTrue);
    });

    test('overlaps returns false for disjoint ranges', () {
      const highlight = TextHighlight(start: 5, end: 10, colorId: 'yellow');

      expect(highlight.overlaps(0, 5), isFalse);
      expect(highlight.overlaps(10, 15), isFalse);
    });
  });

  group('HighlightField', () {
    test('storageKey round trips via fromStorageKey', () {
      for (final field in HighlightField.values) {
        expect(HighlightField.fromStorageKey(field.storageKey), field);
      }
    });

    test('fromStorageKey returns null for unknown keys', () {
      expect(HighlightField.fromStorageKey('nope'), isNull);
    });
  });
}

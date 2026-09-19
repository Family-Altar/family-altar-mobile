import 'package:family_altar/screens/reader/domain/text_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextHighlight', () {
    test('toJson/fromJson round trip', () {
      const highlight = TextHighlight(
        id: 'h1',
        start: 3,
        end: 10,
        colorId: 'green',
      );

      final json = highlight.toJson();
      final decoded = TextHighlight.fromJson(json);

      expect(decoded, highlight);
    });

    test('toJson/fromJson round trip with snippet and note', () {
      const highlight = TextHighlight(
        id: 'h1',
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
        id: 'h1',
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

    test('fromJson synthesizes a stable id when absent (legacy data)', () {
      const raw = {'s': 1, 'e': 2, 'c': 'yellow'};

      expect(TextHighlight.fromJson(raw).id, TextHighlight.fromJson(raw).id);
    });

    test('fromJson uses the stored id when present', () {
      final decoded = TextHighlight.fromJson(const {
        'id': 'stored-id',
        's': 1,
        'e': 2,
        'c': 'yellow',
      });

      expect(decoded.id, 'stored-id');
    });

    test('overlaps detects intersecting ranges', () {
      const highlight = TextHighlight(
        id: 'h1',
        start: 5,
        end: 10,
        colorId: 'yellow',
      );

      expect(highlight.overlaps(0, 6), isTrue);
      expect(highlight.overlaps(9, 15), isTrue);
      expect(highlight.overlaps(6, 8), isTrue);
    });

    test('overlaps returns false for disjoint ranges', () {
      const highlight = TextHighlight(
        id: 'h1',
        start: 5,
        end: 10,
        colorId: 'yellow',
      );

      expect(highlight.overlaps(0, 5), isFalse);
      expect(highlight.overlaps(10, 15), isFalse);
    });
  });

  group('generateHighlightId', () {
    test('produces distinct ids across calls', () {
      final ids = List.generate(50, (_) => generateHighlightId());
      expect(ids.toSet(), hasLength(ids.length));
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

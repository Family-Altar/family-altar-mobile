import 'package:family_altar/models/volume.dart';
import 'package:family_altar/screens/reader/cubit/highlight_cubit.dart';
import 'package:family_altar/screens/reader/domain/text_highlight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final date = DateTime(2026, 8, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HighlightCubit', () {
    test('loadForDate on empty storage yields no highlights', () async {
      final cubit = HighlightCubit();
      await cubit.loadForDate(date: date, volume: Volume.one);

      expect(cubit.state.forField(HighlightField.quote), isEmpty);
      expect(cubit.state.currentDate, date);
      expect(cubit.state.currentVolume, Volume.one);
    });

    test('addHighlight persists and reloading reproduces it', () async {
      final cubit = HighlightCubit();
      await cubit.loadForDate(date: date, volume: Volume.one);
      await cubit.addHighlight(
        field: HighlightField.quote,
        start: 2,
        end: 8,
        colorId: 'green',
        snippet: 'example',
      );

      expect(cubit.state.forField(HighlightField.quote), [
        const TextHighlight(
          start: 2,
          end: 8,
          colorId: 'green',
          snippet: 'example',
        ),
      ]);

      final reloaded = HighlightCubit();
      await reloaded.loadForDate(date: date, volume: Volume.one);
      expect(reloaded.state.forField(HighlightField.quote), [
        const TextHighlight(
          start: 2,
          end: 8,
          colorId: 'green',
          snippet: 'example',
        ),
      ]);
    });

    test(
      'addHighlight with an overlapping range replaces the prior one',
      () async {
        final cubit = HighlightCubit();
        await cubit.loadForDate(date: date, volume: Volume.one);
        await cubit.addHighlight(
          field: HighlightField.quote,
          start: 0,
          end: 10,
          colorId: 'yellow',
          snippet: 'yellow bit',
        );
        await cubit.addHighlight(
          field: HighlightField.quote,
          start: 5,
          end: 15,
          colorId: 'blue',
          snippet: 'blue bit',
        );

        expect(cubit.state.forField(HighlightField.quote), [
          const TextHighlight(
            start: 5,
            end: 15,
            colorId: 'blue',
            snippet: 'blue bit',
          ),
        ]);
      },
    );

    test('removeHighlight clears it and persists the removal', () async {
      final cubit = HighlightCubit();
      await cubit.loadForDate(date: date, volume: Volume.one);
      await cubit.addHighlight(
        field: HighlightField.title,
        start: 0,
        end: 4,
        colorId: 'pink',
        snippet: 'Titl',
      );
      await cubit.removeHighlight(
        field: HighlightField.title,
        highlight: const TextHighlight(start: 0, end: 4, colorId: 'pink'),
      );

      expect(cubit.state.forField(HighlightField.title), isEmpty);

      final reloaded = HighlightCubit();
      await reloaded.loadForDate(date: date, volume: Volume.one);
      expect(reloaded.state.forField(HighlightField.title), isEmpty);
    });

    test('changeHighlightColor updates the color in place', () async {
      final cubit = HighlightCubit();
      await cubit.loadForDate(date: date, volume: Volume.one);
      await cubit.addHighlight(
        field: HighlightField.scripture,
        start: 1,
        end: 3,
        colorId: 'orange',
        snippet: 'ab',
      );
      await cubit.changeHighlightColor(
        field: HighlightField.scripture,
        highlight: const TextHighlight(start: 1, end: 3, colorId: 'orange'),
        newColorId: 'blue',
      );

      expect(cubit.state.forField(HighlightField.scripture), [
        const TextHighlight(
          start: 1,
          end: 3,
          colorId: 'blue',
          snippet: 'ab',
        ),
      ]);
    });

    test('setNote adds a note and persists it', () async {
      final cubit = HighlightCubit();
      await cubit.loadForDate(date: date, volume: Volume.one);
      await cubit.addHighlight(
        field: HighlightField.quote,
        start: 0,
        end: 5,
        colorId: 'green',
        snippet: 'hello',
      );
      await cubit.setNote(
        field: HighlightField.quote,
        highlight: const TextHighlight(
          start: 0,
          end: 5,
          colorId: 'green',
          snippet: 'hello',
        ),
        note: 'remember this',
      );

      expect(
        cubit.state.forField(HighlightField.quote).single.note,
        'remember this',
      );

      final reloaded = HighlightCubit();
      await reloaded.loadForDate(date: date, volume: Volume.one);
      expect(
        reloaded.state.forField(HighlightField.quote).single.note,
        'remember this',
      );
    });

    test('setNote with null clears an existing note', () async {
      final cubit = HighlightCubit();
      await cubit.loadForDate(date: date, volume: Volume.one);
      await cubit.addHighlight(
        field: HighlightField.quote,
        start: 0,
        end: 5,
        colorId: 'green',
        snippet: 'hello',
      );
      await cubit.setNote(
        field: HighlightField.quote,
        highlight: const TextHighlight(
          start: 0,
          end: 5,
          colorId: 'green',
          snippet: 'hello',
        ),
        note: 'temp',
      );
      await cubit.setNote(
        field: HighlightField.quote,
        highlight: const TextHighlight(
          start: 0,
          end: 5,
          colorId: 'green',
          snippet: 'hello',
          note: 'temp',
        ),
        note: null,
      );

      expect(cubit.state.forField(HighlightField.quote).single.note, isNull);
    });

    test(
      'volume-namespaced storage keys do not leak across volumes',
      () async {
        final cubit = HighlightCubit();
        await cubit.loadForDate(date: date, volume: Volume.one);
        await cubit.addHighlight(
          field: HighlightField.quote,
          start: 0,
          end: 4,
          colorId: 'green',
          snippet: 'abcd',
        );

        await cubit.loadForDate(date: date, volume: Volume.two);
        expect(cubit.state.forField(HighlightField.quote), isEmpty);

        await cubit.loadForDate(date: date, volume: Volume.one);
        expect(cubit.state.forField(HighlightField.quote), [
          const TextHighlight(
            start: 0,
            end: 4,
            colorId: 'green',
            snippet: 'abcd',
          ),
        ]);
      },
    );
  });

  group('loadAllHighlights', () {
    test('returns an empty list when there is no stored data', () async {
      final entries = await loadAllHighlights(Volume.one);
      expect(entries, isEmpty);
    });

    test('flattens highlights across dates and fields, newest first', () async {
      final earlier = HighlightCubit();
      await earlier.loadForDate(date: DateTime(2026), volume: Volume.one);
      await earlier.addHighlight(
        field: HighlightField.scripture,
        start: 0,
        end: 3,
        colorId: 'yellow',
        snippet: 'Jan',
      );

      final later = HighlightCubit();
      await later.loadForDate(date: DateTime(2026, 6), volume: Volume.one);
      await later.addHighlight(
        field: HighlightField.quote,
        start: 0,
        end: 3,
        colorId: 'blue',
        snippet: 'Jun',
      );

      final entries = await loadAllHighlights(Volume.one);

      expect(entries, hasLength(2));
      expect(entries[0].date, DateTime(2026, 6));
      expect(entries[0].field, HighlightField.quote);
      expect(entries[0].highlight.snippet, 'Jun');
      expect(entries[1].date, DateTime(2026));
      expect(entries[1].field, HighlightField.scripture);
      expect(entries[1].highlight.snippet, 'Jan');
    });

    test('only includes highlights for the requested volume', () async {
      final cubit = HighlightCubit();
      await cubit.loadForDate(date: date, volume: Volume.two);
      await cubit.addHighlight(
        field: HighlightField.title,
        start: 0,
        end: 2,
        colorId: 'pink',
        snippet: 'Hi',
      );

      expect(await loadAllHighlights(Volume.one), isEmpty);
      expect(await loadAllHighlights(Volume.two), hasLength(1));
    });
  });
}

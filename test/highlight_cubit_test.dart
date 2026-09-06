import 'dart:convert';

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

      final added = cubit.state.forField(HighlightField.quote).single;
      expect(added.start, 2);
      expect(added.end, 8);
      expect(added.colorId, 'green');
      expect(added.snippet, 'example');

      final reloaded = HighlightCubit();
      await reloaded.loadForDate(date: date, volume: Volume.one);
      // The persisted id round trips, so the reloaded highlight is the
      // same one that was added, not just a field-for-field match.
      expect(reloaded.state.forField(HighlightField.quote), [added]);
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

        final remaining = cubit.state.forField(HighlightField.quote).single;
        expect(remaining.start, 5);
        expect(remaining.end, 15);
        expect(remaining.colorId, 'blue');
        expect(remaining.snippet, 'blue bit');
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
      final added = cubit.state.forField(HighlightField.title).single;
      await cubit.removeHighlight(
        field: HighlightField.title,
        highlight: added,
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
      final added = cubit.state.forField(HighlightField.scripture).single;
      await cubit.changeHighlightColor(
        field: HighlightField.scripture,
        highlight: added,
        newColorId: 'blue',
      );

      final updated = cubit.state.forField(HighlightField.scripture).single;
      expect(updated.id, added.id);
      expect(updated.start, 1);
      expect(updated.end, 3);
      expect(updated.colorId, 'blue');
      expect(updated.snippet, 'ab');
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
      final added = cubit.state.forField(HighlightField.quote).single;
      await cubit.setNote(
        field: HighlightField.quote,
        highlight: added,
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
      final added = cubit.state.forField(HighlightField.quote).single;
      await cubit.setNote(
        field: HighlightField.quote,
        highlight: added,
        note: 'temp',
      );
      final withTempNote = cubit.state.forField(HighlightField.quote).single;
      await cubit.setNote(
        field: HighlightField.quote,
        highlight: withTempNote,
        note: null,
      );

      expect(cubit.state.forField(HighlightField.quote).single.note, isNull);
    });

    test(
      'a highlight on a given month+day is visible from the same '
      'month+day in a different real year — the reading plan repeats '
      "every year, so a highlight isn't bound to the year it was made in",
      () async {
        final cubit = HighlightCubit();
        await cubit.loadForDate(date: DateTime(2026), volume: Volume.one);
        await cubit.addHighlight(
          field: HighlightField.quote,
          start: 0,
          end: 5,
          colorId: 'green',
          snippet: 'hello',
        );

        final reloaded = HighlightCubit();
        await reloaded.loadForDate(date: DateTime(2025), volume: Volume.one);

        expect(reloaded.state.forField(HighlightField.quote), hasLength(1));
        expect(
          reloaded.state.forField(HighlightField.quote).single.snippet,
          'hello',
        );
      },
    );

    test(
      'legacy full-date ("yyyy-MM-dd") storage keys are migrated to '
      'month+day keys on load',
      () async {
        SharedPreferences.setMockInitialValues({
          'highlights': json.encode({
            '2025-01-01': {
              'quote': [
                {'id': 'legacy-1', 's': 0, 'e': 5, 'c': 'green', 'tx': 'old'},
              ],
            },
          }),
        });

        final cubit = HighlightCubit();
        await cubit.loadForDate(date: DateTime(2026), volume: Volume.one);

        expect(cubit.state.forField(HighlightField.quote), hasLength(1));
        expect(
          cubit.state.forField(HighlightField.quote).single.snippet,
          'old',
        );

        final prefs = await SharedPreferences.getInstance();
        final stored =
            json.decode(prefs.getString('highlights')!) as Map<String, dynamic>;
        expect(stored.keys, contains('01-01'));
        expect(stored.keys, isNot(contains('2025-01-01')));
      },
    );

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
        final added = cubit.state.forField(HighlightField.quote).single;

        await cubit.loadForDate(date: date, volume: Volume.two);
        expect(cubit.state.forField(HighlightField.quote), isEmpty);

        await cubit.loadForDate(date: date, volume: Volume.one);
        expect(cubit.state.forField(HighlightField.quote), [added]);
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

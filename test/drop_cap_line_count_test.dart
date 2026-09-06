import 'package:family_altar/screens/reader/cubit/highlight_cubit.dart';
import 'package:family_altar/screens/reader/widgets/drop_cap_highlightable_text.dart';
import 'package:family_altar/screens/reader/widgets/highlightable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// The text wrapped beside the drop cap should never exceed 3 lines,
// however long the first sentence of the quote is — a 4th (or partial)
// line squeezed into the narrow drop-cap column reads badly; anything
// past 3 lines should start a fresh, full-width line below instead.
const _sept5Quote =
    'Notice, every year the high priest entered into that place. The '
    'congregation followed him up. And when he went into this great '
    'place where the veil dropped behind him, the inner courts, the '
    'holiest of holies, no one dared to go after him. Then he was '
    'alone with God.';

const _jesusQuote =
    'Jesus Christ has purchased every salvation and every healing '
    "when He died at Calvary. And don't never let any man ever tell "
    "you that's there's anything about him that can heal you, for he's "
    'absolutely wrong, either mentally or Scripturally. He is '
    'Scripturally wrong. And he...';

/// Pumps [DropCapHighlightableText] full-height on a tall surface (so a
/// long quote never trips an unrelated overflow) and returns how many
/// lines its side (beside-the-cap) region actually rendered.
Future<int> _sideLineCount(
  WidgetTester tester, {
  required String quote,
  required TextStyle dropCapStyle,
  required TextStyle baseStyle,
  double width = 360,
}) async {
  await tester.binding.setSurfaceSize(Size(width + 40, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => HighlightCubit(),
        child: Scaffold(
          body: SizedBox(
            width: width,
            child: DropCapHighlightableText(
              quote: quote,
              dropCapStyle: dropCapStyle,
              baseStyle: baseStyle,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final sideRichText = find.byType(HighlightableRichText).first;
  final sideParagraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: sideRichText, matching: find.byType(RichText)),
  );
  final singleLineHeight =
      TextPainter(
        text: TextSpan(style: baseStyle),
        textDirection: TextDirection.ltr,
      ).preferredLineHeight;
  return (sideParagraph.size.height / singleLineHeight).round();
}

void main() {
  testWidgets('text beside the drop cap is capped at 3 lines', (tester) async {
    final lineCount = await _sideLineCount(
      tester,
      quote: _sept5Quote,
      dropCapStyle: const TextStyle(fontSize: 50),
      baseStyle: const TextStyle(fontSize: 16, height: 1.2),
    );

    expect(
      lineCount,
      lessThanOrEqualTo(3),
      reason:
          'Text beside the drop cap wrapped to $lineCount lines — it '
          'should never exceed 3; the rest of the sentence should '
          'continue on a full-width line below instead.',
    );
    expect(
      lineCount,
      equals(3),
      reason:
          'This sentence is long enough that it should actually need '
          'all 3 lines beside the cap — a lower count here would mean '
          'the test fixture stopped being a meaningful check, not that '
          'the cap logic improved.',
    );
  });

  testWidgets(
    'a disproportionately tall cap still wraps at most 3 lines beside it',
    (tester) async {
      // A cap this tall relative to a small reading font size would need
      // 4+ lines beside it before the cap was clamped.
      final lineCount = await _sideLineCount(
        tester,
        quote: _sept5Quote,
        dropCapStyle: const TextStyle(fontSize: 80),
        baseStyle: const TextStyle(fontSize: 12, height: 1.2),
      );

      expect(
        lineCount,
        lessThanOrEqualTo(3),
        reason:
            'An 80pt cap beside a 12pt line naturally needs more than 3 '
            'lines to match its height — it wrapped to $lineCount lines '
            'instead of being capped at 3.',
      );
    },
  );

  testWidgets('stays within 3 lines across the whole reading font-size range', (
    tester,
  ) async {
    // Mirrors reader_screen.dart's dropCap-scales-with-fontSize formula
    // and the settings sheet's 12-28pt slider range. At certain sizes
    // (fontSize 15 was one) a sub-pixel gap between the text-fitting
    // search width and the real rendered column width used to let one
    // extra word spill onto a 4th line.
    for (var fontSize = 12.0; fontSize <= 28.0; fontSize += 1) {
      final lineCount = await _sideLineCount(
        tester,
        quote: _jesusQuote,
        dropCapStyle: TextStyle(
          fontFamily: 'OldEnglish',
          fontSize: fontSize * (50 / 16),
        ),
        baseStyle: TextStyle(fontSize: fontSize, height: 1.2),
      );

      expect(
        lineCount,
        lessThanOrEqualTo(3),
        reason: 'fontSize=$fontSize wrapped to $lineCount lines beside cap',
      );
    }
  });
}

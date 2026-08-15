import 'package:family_altar/screens/reader/domain/text_highlight.dart';
import 'package:family_altar/screens/reader/widgets/highlightable_text.dart';
import 'package:flutter/material.dart';

/// Replaces the `drop_cap_text` package (which only accepts a plain string,
/// with no way to inject highlight spans) for the quote block. Renders the
/// first grapheme large, inline with the rest of the quote, in a single
/// selectable/highlightable span — so, unlike a plain leading `Text` widget,
/// it can be selected and highlighted like the rest of the quote. This
/// approximates a drop cap rather than reproducing the multi-line
/// wrap-around of a true drop cap.
class DropCapHighlightableText extends StatelessWidget {
  const DropCapHighlightableText({
    required this.quote,
    required this.baseStyle,
    required this.dropCapStyle,
    this.selectionActiveNotifier,
    this.scrollAnchorHighlight,
    this.scrollAnchorKey,
    super.key,
  });

  final String quote;
  final TextStyle baseStyle;
  final TextStyle dropCapStyle;
  final ValueNotifier<bool>? selectionActiveNotifier;
  final TextHighlight? scrollAnchorHighlight;
  final Key? scrollAnchorKey;

  @override
  Widget build(BuildContext context) {
    if (quote.isEmpty) return const SizedBox.shrink();

    return HighlightableText(
      text: quote,
      field: HighlightField.quote,
      baseStyle: baseStyle,
      firstCharacterStyle: dropCapStyle,
      selectionActiveNotifier: selectionActiveNotifier,
      scrollAnchorHighlight: scrollAnchorHighlight,
      scrollAnchorKey: scrollAnchorKey,
    );
  }
}

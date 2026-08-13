import 'package:family_altar/screens/reader/domain/text_highlight.dart';
import 'package:family_altar/screens/reader/widgets/highlightable_text.dart';
import 'package:flutter/material.dart';

/// Replaces the `drop_cap_text` package (which only accepts a plain string,
/// with no way to inject highlight spans) for the quote block. Shows the
/// first grapheme large and inline, followed by the rest of the quote in
/// normal, highlightable flow. This approximates a drop cap rather than
/// reproducing the package's multi-line wrap-around.
class DropCapHighlightableText extends StatelessWidget {
  const DropCapHighlightableText({
    required this.quote,
    required this.baseStyle,
    required this.dropCapStyle,
    this.dropCapPadding = const EdgeInsets.only(right: 8),
    this.selectionActiveNotifier,
    super.key,
  });

  final String quote;
  final TextStyle baseStyle;
  final TextStyle dropCapStyle;
  final EdgeInsets dropCapPadding;
  final ValueNotifier<bool>? selectionActiveNotifier;

  @override
  Widget build(BuildContext context) {
    if (quote.isEmpty) return const SizedBox.shrink();

    final firstGrapheme = quote.characters.first;
    final rest = quote.substring(firstGrapheme.length);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: dropCapPadding,
          child: Text(firstGrapheme, style: dropCapStyle),
        ),
        Expanded(
          child: HighlightableText(
            text: rest,
            field: HighlightField.quote,
            baseStyle: baseStyle,
            selectionActiveNotifier: selectionActiveNotifier,
          ),
        ),
      ],
    );
  }
}

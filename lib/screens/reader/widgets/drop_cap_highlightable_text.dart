import 'package:family_altar/screens/reader/cubit/highlight_cubit.dart';
import 'package:family_altar/screens/reader/domain/text_highlight.dart';
import 'package:family_altar/screens/reader/widgets/highlightable_text.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Replaces the `drop_cap_text` package (which only accepts a plain string,
/// with no way to inject highlight spans) for the quote block. Reproduces
/// its "inside" drop-cap layout — a large first letter with the next few
/// lines of text wrapping around it at reduced width, then the remaining
/// lines resuming at full width below — while keeping the quote selectable
/// and highlightable.
///
/// The letter sits outside the selectable/highlightable [HighlightableText]
/// widgets beside and below it, but still counts as part of the quote's
/// addressable offset space (via [HighlightableText.leadingText]) — so a
/// highlight that starts on the first word snaps back to cover the letter
/// too, and this widget tints the letter to match whenever that happens —
/// live, while the selection is still being dragged, not just once it's
/// released and a color is picked.
class DropCapHighlightableText extends StatefulWidget {
  const DropCapHighlightableText({
    required this.quote,
    required this.baseStyle,
    required this.dropCapStyle,
    this.dropCapPadding = const EdgeInsets.only(right: 8),
    this.selectionActiveNotifier,
    this.scrollAnchorHighlight,
    this.scrollAnchorKey,
    super.key,
  });

  final String quote;
  final TextStyle baseStyle;
  final TextStyle dropCapStyle;
  final EdgeInsets dropCapPadding;
  final ValueNotifier<bool>? selectionActiveNotifier;
  final TextHighlight? scrollAnchorHighlight;
  final Key? scrollAnchorKey;

  @override
  State<DropCapHighlightableText> createState() =>
      _DropCapHighlightableTextState();
}

class _DropCapHighlightableTextState extends State<DropCapHighlightableText> {
  final ValueNotifier<bool> _dropCapSelectionPreview = ValueNotifier(false);

  @override
  void dispose() {
    _dropCapSelectionPreview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quote.isEmpty) return const SizedBox.shrink();

    final dropCap = widget.quote.characters.first;
    final rest = widget.quote.substring(dropCap.length);

    final highlights = context.watch<HighlightCubit>().state.forField(
      HighlightField.quote,
    );
    TextHighlight? coveringDropCap;
    for (final highlight in highlights) {
      if (highlight.start < dropCap.length && highlight.end > 0) {
        coveringDropCap = highlight;
        break;
      }
    }
    final dropCapColor =
        coveringDropCap == null
            ? null
            : context
                .highlightColor(coveringDropCap.colorId)
                .withValues(alpha: context.isDarkMode ? 0.42 : 0.62);

    // Matches the tint SelectableText paints behind an in-progress
    // selection, so the drop cap visually joins the live drag preview
    // instead of only updating once a highlight color is actually picked.
    final liveSelectionColor =
        TextSelectionTheme.of(context).selectionColor ??
        DefaultSelectionStyle.of(context).selectionColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.4);

    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    // Normalizes the line height to 1x the font size instead of this
    // decorative font's own (much taller) natural line metrics — matching
    // what the drop_cap_text package forces on its cap style. Left alone,
    // the glyph sits low/small inside an oversized invisible line box, and
    // the inflated height throws off the row count below.
    final capStyle = widget.dropCapStyle.copyWith(
      height: widget.dropCapStyle.height ?? 1,
    );

    // Deliberately not scaled by the ambient text scaler (matching the
    // drop_cap_text package, which measures and paints its cap via a bare
    // RichText — unlike Text, it doesn't pick up MediaQuery's text scaler
    // on its own). Only the body text should grow with accessibility text
    // size; scaling the already-oversized cap too would throw off the
    // capHeight/lineHeight ratio driving the row count below, in a way
    // that varies by device instead of matching a fixed reference size.
    final capPainter = TextPainter(
      text: TextSpan(text: dropCap, style: capStyle),
      textDirection: textDirection,
    )..layout();
    final capWidth = capPainter.width + widget.dropCapPadding.horizontal;
    final capHeight = capPainter.height + widget.dropCapPadding.vertical;

    final lineHeight =
        TextPainter(
          text: TextSpan(style: widget.baseStyle),
          textDirection: textDirection,
          textScaler: textScaler,
        ).preferredLineHeight;
    final rows = (capHeight / lineHeight).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundsWidth = (constraints.maxWidth - capWidth).clamp(
          1.0,
          constraints.maxWidth,
        );

        // Finds how much of `rest` fits in the first `rows` lines at
        // `boundsWidth`, mirroring the drop_cap_text package: lay out
        // unconstrained-height to locate the character at the bottom of
        // the last side-by-side row, then re-check with maxLines to see
        // whether that many lines actually got used.
        var sideEnd = rest.length;
        if (rows > 0 && rest.isNotEmpty) {
          final restPainter = TextPainter(
            text: TextSpan(text: rest, style: widget.baseStyle),
            textDirection: textDirection,
            textScaler: textScaler,
          )..layout(maxWidth: boundsWidth);
          final charIndex =
              restPainter
                  .getPositionForOffset(Offset(0, rows * lineHeight))
                  .offset;
          restPainter
            ..maxLines = rows
            ..layout(maxWidth: boundsWidth);
          if (restPainter.didExceedMaxLines) sideEnd = charIndex;
        }

        final sideText = rest.substring(0, sideEnd);
        final belowText = rest.substring(sideEnd);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: widget.dropCapPadding,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _dropCapSelectionPreview,
                    builder:
                        (context, previewing, _) => Text(
                          dropCap,
                          textScaler: TextScaler.noScaling,
                          style: capStyle.copyWith(
                            backgroundColor:
                                previewing ? liveSelectionColor : dropCapColor,
                          ),
                        ),
                  ),
                ),
                Expanded(
                  child: HighlightableText(
                    text: sideText,
                    leadingText: dropCap,
                    field: HighlightField.quote,
                    baseStyle: widget.baseStyle,
                    selectionActiveNotifier: widget.selectionActiveNotifier,
                    leadingTextPreviewNotifier: _dropCapSelectionPreview,
                    scrollAnchorHighlight: widget.scrollAnchorHighlight,
                    scrollAnchorKey: widget.scrollAnchorKey,
                  ),
                ),
              ],
            ),
            if (belowText.isNotEmpty)
              HighlightableText(
                text: belowText,
                leadingText: '$dropCap$sideText',
                field: HighlightField.quote,
                baseStyle: widget.baseStyle,
                selectionActiveNotifier: widget.selectionActiveNotifier,
                scrollAnchorHighlight: widget.scrollAnchorHighlight,
                scrollAnchorKey: widget.scrollAnchorKey,
              ),
          ],
        );
      },
    );
  }
}

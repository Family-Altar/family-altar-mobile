import 'package:family_altar/screens/reader/cubit/highlight_cubit.dart';
import 'package:family_altar/screens/reader/domain/text_highlight.dart';
import 'package:family_altar/screens/reader/widgets/highlight_color_toolbar.dart';
import 'package:family_altar/screens/reader/widgets/highlightable_text.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Replaces the `drop_cap_text` package (which only accepts a plain string,
/// with no way to inject highlight spans) for the quote block. Reproduces
/// its "inside" drop-cap layout — a large first letter with the next few
/// lines of text wrapping around it at reduced width, then the remaining
/// lines resuming at full width below — while keeping the quote selectable
/// and highlightable.
///
/// The letter sits outside the two [HighlightableRichText]s beside and
/// below it, but still counts as part of the quote's addressable offset
/// space (via each child's [HighlightableRichText.offset]) — so a
/// highlight that starts on the first word snaps back to cover the letter
/// too, and this widget tints the letter to match whenever that happens —
/// live, while the selection is still being dragged, not just once it's
/// released and a color is picked.
///
/// The whole layout sits inside a single [SelectionArea], and each of the
/// two rich-text children is wrapped in its own [SelectionListener] — so
/// a drag that crosses the wrap boundary produces one continuous
/// selection, and the composed range covers the full straddling passage.
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
  final SelectionListenerNotifier _sideNotifier = SelectionListenerNotifier();
  final SelectionListenerNotifier _belowNotifier = SelectionListenerNotifier();
  final AddNoteBubbleHost _addNoteBubble = AddNoteBubbleHost();

  @override
  void initState() {
    super.initState();
    _sideNotifier.addListener(_onSelectionChanged);
    _belowNotifier.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    _sideNotifier
      ..removeListener(_onSelectionChanged)
      ..dispose();
    _belowNotifier
      ..removeListener(_onSelectionChanged)
      ..dispose();
    _dropCapSelectionPreview.dispose();
    _addNoteBubble.dismiss();
    super.dispose();
  }

  ({int start, int end})? _rangeOf(SelectionListenerNotifier notifier) {
    if (!notifier.registered) return null;
    final details = notifier.selection;
    if (details.status != SelectionStatus.uncollapsed) return null;
    final range = details.range;
    if (range == null) return null;
    return (start: range.startOffset, end: range.endOffset);
  }

  void _onSelectionChanged() {
    final side = _rangeOf(_sideNotifier);
    final below = _rangeOf(_belowNotifier);
    final anyActive = side != null || below != null;
    widget.selectionActiveNotifier?.value = anyActive;
    _dropCapSelectionPreview.value = side != null && side.start == 0;
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
    // Capped at 3 — a taller cap (e.g. from a larger reading font size)
    // would otherwise wrap more lines beside it than reads well.
    final rows = (capHeight / lineHeight).ceil().clamp(0, 3);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundsWidth = (constraints.maxWidth - capWidth).clamp(
          1.0,
          constraints.maxWidth,
        );
        final searchWidth = (boundsWidth - 3).clamp(1.0, boundsWidth);

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
          )..layout(maxWidth: searchWidth);
          final charIndex =
              restPainter
                  .getPositionForOffset(Offset(0, rows * lineHeight))
                  .offset;
          restPainter
            ..maxLines = rows
            ..layout(maxWidth: searchWidth);
          if (restPainter.didExceedMaxLines) sideEnd = charIndex;
        }

        final sideText = rest.substring(0, sideEnd);
        final belowText = rest.substring(sideEnd);
        final capLen = dropCap.length;

        // `fullText` and the child `offset`s below share one addressable
        // space so composed selection offsets, and the highlight ids they
        // become, line up with what's already persisted for this quote.
        final fullText = '$dropCap$sideText$belowText';

        return SelectionArea(
          contextMenuBuilder:
              (ctx, state) => _buildColorPickerToolbar(
                ctx,
                state,
                fullText: fullText,
                capLen: capLen,
                sideLen: sideText.length,
              ),
          child: Column(
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
                                  previewing
                                      ? liveSelectionColor
                                      : dropCapColor,
                            ),
                          ),
                    ),
                  ),
                  Expanded(
                    child: SelectionListener(
                      selectionNotifier: _sideNotifier,
                      child: HighlightableRichText(
                        text: sideText,
                        field: HighlightField.quote,
                        baseStyle: widget.baseStyle,
                        offset: capLen,
                        scrollAnchorHighlight: widget.scrollAnchorHighlight,
                        scrollAnchorKey: widget.scrollAnchorKey,
                        maxLines: rows > 0 ? rows : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (belowText.isNotEmpty)
                SelectionListener(
                  selectionNotifier: _belowNotifier,
                  child: HighlightableRichText(
                    text: belowText,
                    field: HighlightField.quote,
                    baseStyle: widget.baseStyle,
                    offset: capLen + sideText.length,
                    scrollAnchorHighlight: widget.scrollAnchorHighlight,
                    scrollAnchorKey: widget.scrollAnchorKey,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorPickerToolbar(
    BuildContext ctx,
    SelectableRegionState state, {
    required String fullText,
    required int capLen,
    required int sideLen,
  }) {
    final side = _rangeOf(_sideNotifier);
    final below = _rangeOf(_belowNotifier);

    int? rawStart;
    int? rawEnd;
    if (side != null && below == null) {
      rawStart = capLen + side.start;
      rawEnd = capLen + side.end;
    } else if (below != null && side == null) {
      rawStart = capLen + sideLen + below.start;
      rawEnd = capLen + sideLen + below.end;
    } else if (side != null && below != null) {
      // Side is always visually above below in reading order, so a drag
      // that touches both must span from the side's start to the below's
      // end.
      rawStart = capLen + side.start;
      rawEnd = capLen + sideLen + below.end;
    } else {
      return const SizedBox.shrink();
    }

    var (fieldStart, fieldEnd) = snapToWordBoundaries(
      fullText,
      rawStart,
      rawEnd,
    );

    // A drag that reaches the side text's own left edge — i.e. up against
    // the drop cap rendered by the sibling widget — reads as "select from
    // the very start", so it should pull in the drop cap letter too. Plain
    // word-boundary snapping can't do this on its own when the cap is a
    // one-letter word of its own (e.g. "I will..."), since the space after
    // it blocks the word-char adjacency check.
    if (side != null && side.start == 0) {
      fieldStart = 0;
    }

    if (fieldEnd <= fieldStart) return const SizedBox.shrink();

    final anchors = state.contextMenuAnchors;

    return TextSelectionToolbar(
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      children: [
        HighlightColorToolbar(
          colorIds: ctx.highlightColorIds,
          onColorSelected: (colorId) {
            // `ctx` here is the context menu's own Overlay context, which
            // sits outside the BlocProvider<HighlightCubit> subtree — read
            // the cubit from this State's context instead.
            final snippet = fullText.substring(fieldStart, fieldEnd);
            final highlightId = generateHighlightId();
            context.read<HighlightCubit>().addHighlight(
              field: HighlightField.quote,
              start: fieldStart,
              end: fieldEnd,
              colorId: colorId,
              snippet: snippet,
              id: highlightId,
            );
            state
              ..hideToolbar()
              ..clearSelection();
            _addNoteBubble.show(
              toolbarContext: ctx,
              hostContext: context,
              anchors: anchors,
              field: HighlightField.quote,
              highlight: TextHighlight(
                id: highlightId,
                start: fieldStart,
                end: fieldEnd,
                colorId: colorId,
                snippet: snippet,
              ),
            );
          },
        ),
      ],
    );
  }
}

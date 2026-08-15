import 'dart:async';

import 'package:family_altar/screens/reader/cubit/highlight_cubit.dart';
import 'package:family_altar/screens/reader/domain/text_highlight.dart';
import 'package:family_altar/screens/reader/widgets/highlight_color_toolbar.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Splits [text] into plain/highlighted [InlineSpan]s from a sorted,
/// non-overlapping list of [highlights]. Stale offsets (from content that
/// changed since a highlight was saved) are clamped to the text bounds and
/// any highlight left with no width, or that starts before the previous
/// span's end, is skipped rather than throwing.
List<InlineSpan> buildHighlightSpans({
  required String text,
  required List<TextHighlight> highlights,
  required TextStyle baseStyle,
  required Color Function(TextHighlight) resolveColor,
  required void Function(TextHighlight, TapDownDetails) onHighlightTapDown,
  required List<TapGestureRecognizer> recognizerSink,
  int styleBoundary = 0,
  TextStyle Function(TextStyle)? styleBeforeBoundary,
  TextHighlight? scrollAnchorHighlight,
  Key? scrollAnchorKey,
}) {
  List<InlineSpan> spansForRun(
    int start,
    int end,
    TextStyle style, {
    TapGestureRecognizer? recognizer,
  }) {
    if (styleBeforeBoundary == null || styleBoundary <= start || end <= start) {
      return [
        TextSpan(
          text: text.substring(start, end),
          style: style,
          recognizer: recognizer,
        ),
      ];
    }
    if (styleBoundary >= end) {
      return [
        TextSpan(
          text: text.substring(start, end),
          style: styleBeforeBoundary(style),
          recognizer: recognizer,
        ),
      ];
    }
    return [
      TextSpan(
        text: text.substring(start, styleBoundary),
        style: styleBeforeBoundary(style),
        recognizer: recognizer,
      ),
      TextSpan(
        text: text.substring(styleBoundary, end),
        style: style,
        recognizer: recognizer,
      ),
    ];
  }

  if (highlights.isEmpty) {
    return spansForRun(0, text.length, baseStyle);
  }

  final sorted = [...highlights]..sort((a, b) => a.start.compareTo(b.start));
  final spans = <InlineSpan>[];
  var cursor = 0;

  for (final highlight in sorted) {
    final start = highlight.start.clamp(0, text.length);
    final end = highlight.end.clamp(0, text.length);
    if (end <= start || start < cursor) continue;

    if (start > cursor) {
      spans.addAll(spansForRun(cursor, start, baseStyle));
    }

    // Anchors a zero-size placeholder at the exact start of the target
    // highlight so the reader can scroll to precisely where it sits,
    // instead of to the top of the whole (possibly much taller) field.
    if (scrollAnchorKey != null && highlight == scrollAnchorHighlight) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox.shrink(key: scrollAnchorKey),
        ),
      );
    }

    final recognizer =
        TapGestureRecognizer()
          ..onTapDown = (details) => onHighlightTapDown(highlight, details);
    recognizerSink.add(recognizer);

    spans.addAll(
      spansForRun(
        start,
        end,
        baseStyle.copyWith(backgroundColor: resolveColor(highlight)),
        recognizer: recognizer,
      ),
    );

    cursor = end;
  }

  if (cursor < text.length) {
    spans.addAll(spansForRun(cursor, text.length, baseStyle));
  }

  return spans;
}

/// Renders [text] as selectable, highlightable rich text for [field].
/// Selecting a range shows a color-swatch popup instead of the default
/// copy/paste toolbar; tapping an existing highlight reopens it with a
/// remove option.
class HighlightableText extends StatefulWidget {
  const HighlightableText({
    required this.text,
    required this.field,
    required this.baseStyle,
    this.textAlign = TextAlign.left,
    this.prefixText,
    this.selectionActiveNotifier,
    this.textScaler,
    this.firstCharacterStyle,
    this.scrollAnchorHighlight,
    this.scrollAnchorKey,
    super.key,
  });

  final String text;
  final HighlightField field;
  final TextStyle baseStyle;
  final TextAlign textAlign;
  final TextScaler? textScaler;

  /// Rendered ahead of [text] but excluded from highlighting/offsets.
  final String? prefixText;

  final TextStyle? firstCharacterStyle;

  final TextHighlight? scrollAnchorHighlight;
  final Key? scrollAnchorKey;

  /// Set to true while a selection is active, so callers can suppress
  /// competing gestures (e.g. swipe navigation) during text selection.
  final ValueNotifier<bool>? selectionActiveNotifier;

  @override
  State<HighlightableText> createState() => _HighlightableTextState();
}

class _HighlightableTextState extends State<HighlightableText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final highlights = context.watch<HighlightCubit>().state.forField(
      widget.field,
    );
    final prefixLen = widget.prefixText?.length ?? 0;

    final span = TextSpan(
      style: widget.baseStyle,
      children: [
        if (widget.prefixText != null)
          TextSpan(text: widget.prefixText, style: widget.baseStyle),
        ...buildHighlightSpans(
          text: widget.text,
          highlights: highlights,
          baseStyle: widget.baseStyle,
          // Rendered as a faint wash rather than a solid tint, so the
          // marker reads as understated even with several highlights
          // visible on the same page.
          resolveColor:
              (h) => context
                  .highlightColor(h.colorId)
                  .withValues(alpha: context.isDarkMode ? 0.42 : 0.62),
          onHighlightTapDown:
              (h, details) =>
                  _showHighlightMenu(context, details.globalPosition, h),
          recognizerSink: _recognizers,
          styleBoundary:
              widget.firstCharacterStyle != null && widget.text.isNotEmpty
                  ? widget.text.characters.first.length
                  : 0,
          styleBeforeBoundary:
              widget.firstCharacterStyle == null
                  ? null
                  : (style) => style.merge(widget.firstCharacterStyle),
          scrollAnchorHighlight: widget.scrollAnchorHighlight,
          scrollAnchorKey: widget.scrollAnchorKey,
        ),
      ],
    );

    return SelectableText.rich(
      span,
      textAlign: widget.textAlign,
      textScaler: widget.textScaler,
      onSelectionChanged: (selection, cause) {
        widget.selectionActiveNotifier?.value =
            selection.isValid && !selection.isCollapsed;
      },
      contextMenuBuilder:
          (ctx, editableTextState) =>
              _buildColorPickerToolbar(ctx, editableTextState, prefixLen),
    );
  }

  Widget _buildColorPickerToolbar(
    BuildContext ctx,
    EditableTextState editableTextState,
    int prefixLen,
  ) {
    final selection = editableTextState.textEditingValue.selection;
    if (!selection.isValid || selection.start == selection.end) {
      return const SizedBox.shrink();
    }

    final contentStart = (selection.start - prefixLen).clamp(
      0,
      widget.text.length,
    );
    final contentEnd = (selection.end - prefixLen).clamp(0, widget.text.length);
    if (contentEnd <= contentStart) return const SizedBox.shrink();

    final anchors = editableTextState.contextMenuAnchors;

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
            final snippet = widget.text.substring(contentStart, contentEnd);
            context.read<HighlightCubit>().addHighlight(
              field: widget.field,
              start: contentStart,
              end: contentEnd,
              colorId: colorId,
              snippet: snippet,
            );
            editableTextState
              ..hideToolbar()
              ..userUpdateTextEditingValue(
                editableTextState.textEditingValue.copyWith(
                  selection: TextSelection.collapsed(offset: selection.end),
                ),
                SelectionChangedCause.tap,
              );
            // Follow the new highlight straight into the note drawer, so
            // adding a note doesn't require a separate tap-to-reopen step.
            unawaited(
              _showNoteDialog(
                context,
                TextHighlight(
                  start: contentStart,
                  end: contentEnd,
                  colorId: colorId,
                  snippet: snippet,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showHighlightMenu(
    BuildContext context,
    Offset globalPosition,
    TextHighlight highlight,
  ) {
    final overlayBox =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    showMenu<void>(
      context: context,
      color: context.dialogBG,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      position: RelativeRect.fromRect(
        globalPosition & const Size(1, 1),
        Offset.zero & overlayBox.size,
      ),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: HighlightColorToolbar(
            colorIds: context.highlightColorIds,
            selectedColorId: highlight.colorId,
            onColorSelected: (colorId) {
              context.read<HighlightCubit>().changeHighlightColor(
                field: widget.field,
                highlight: highlight,
                newColorId: colorId,
              );
              Navigator.of(context).pop();
            },
            onRemove: () {
              context.read<HighlightCubit>().removeHighlight(
                field: widget.field,
                highlight: highlight,
              );
              Navigator.of(context).pop();
            },
            onEditNote: () {
              Navigator.of(context).pop();
              unawaited(_showNoteDialog(context, highlight));
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showNoteDialog(
    BuildContext context,
    TextHighlight highlight,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => NoteSheet(initialNote: highlight.note),
    );

    if (result == null || !context.mounted) return;
    final trimmed = result.trim();
    unawaited(
      context.read<HighlightCubit>().setNote(
        field: widget.field,
        highlight: highlight,
        note: trimmed.isEmpty ? null : trimmed,
      ),
    );
  }
}

/// Bottom sheet for adding/editing a highlight's note. Shared by the
/// reader's inline highlight menu and the highlights list screen.
class NoteSheet extends StatefulWidget {
  const NoteSheet({required this.initialNote, super.key});

  final String? initialNote;

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialNote ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color:
                dark
                    ? Colors.grey.shade700
                    : context.accent.withValues(alpha: 0.2),
            width: 0.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: context.textColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Note',
                  style: AppFonts.bold(context, size: FontSize.large),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  maxLines: 5,
                  minLines: 3,
                  autofocus: true,
                  style: AppFonts.normal(context),
                  decoration: InputDecoration(
                    hintText: 'Add a note…',
                    hintStyle: AppFonts.normal(
                      context,
                    ).copyWith(color: context.textColor.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: context.accent.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: context.dialogCancel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: context.accent,
                        ),
                        onPressed:
                            () => Navigator.of(context).pop(_controller.text),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

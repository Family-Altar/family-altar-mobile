import 'dart:async';

import 'package:family_altar/screens/reader/cubit/highlight_cubit.dart';
import 'package:family_altar/screens/reader/domain/text_highlight.dart';
import 'package:family_altar/screens/reader/widgets/add_note_bubble.dart';
import 'package:family_altar/screens/reader/widgets/highlight_color_toolbar.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether [char] (a single UTF-16 code unit) should be treated as part of
/// a word for [snapToWordBoundaries] purposes.
bool _isWordChar(String char) =>
    RegExp(r"[\p{L}\p{N}']", unicode: true).hasMatch(char);

/// Expands the `[start, end)` range in [text] outward to the nearest word
/// boundaries, so a selection that begins or ends mid-word grabs the whole
/// word instead of a partial one. A boundary already sitting at the edge of
/// a word (or at the string's edge) is left untouched.
(int, int) snapToWordBoundaries(String text, int start, int end) {
  var snappedStart = start;
  if (snappedStart > 0 &&
      snappedStart < text.length &&
      _isWordChar(text[snappedStart - 1]) &&
      _isWordChar(text[snappedStart])) {
    while (snappedStart > 0 && _isWordChar(text[snappedStart - 1])) {
      snappedStart--;
    }
  }

  var snappedEnd = end;
  if (snappedEnd > 0 &&
      snappedEnd < text.length &&
      _isWordChar(text[snappedEnd - 1]) &&
      _isWordChar(text[snappedEnd])) {
    while (snappedEnd < text.length && _isWordChar(text[snappedEnd])) {
      snappedEnd++;
    }
  }

  return (snappedStart, snappedEnd);
}

/// Splits [text] into plain/highlighted [InlineSpan]s from a sorted,
/// non-overlapping list of [highlights]. Stale offsets (from content that
/// changed since a highlight was saved) are clamped to the text bounds and
/// any highlight left with no width, or that starts before the previous
/// span's end, is skipped rather than throwing.
///
/// [offset] shifts highlight offsets before slicing, for callers that only
/// render a suffix of the field's full addressable text (e.g. the text
/// after a separately-rendered drop cap letter) — the [highlights] objects
/// themselves stay in the field's full offset space throughout.
List<InlineSpan> buildHighlightSpans({
  required String text,
  required List<TextHighlight> highlights,
  required TextStyle baseStyle,
  required Color Function(TextHighlight) resolveColor,
  required void Function(TextHighlight, TapDownDetails) onHighlightTapDown,
  required List<TapGestureRecognizer> recognizerSink,
  int offset = 0,
  TextHighlight? scrollAnchorHighlight,
  Key? scrollAnchorKey,
}) {
  if (highlights.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final sorted = [...highlights]..sort((a, b) => a.start.compareTo(b.start));
  final spans = <InlineSpan>[];
  var cursor = 0;

  for (final highlight in sorted) {
    final start = (highlight.start - offset).clamp(0, text.length);
    final end = (highlight.end - offset).clamp(0, text.length);
    if (end <= start || start < cursor) continue;

    if (start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, start), style: baseStyle),
      );
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

    spans.add(
      TextSpan(
        text: text.substring(start, end),
        style: baseStyle.copyWith(backgroundColor: resolveColor(highlight)),
        recognizer: recognizer,
      ),
    );

    cursor = end;
  }

  if (cursor < text.length) {
    spans.add(
      TextSpan(text: text.substring(cursor, text.length), style: baseStyle),
    );
  }

  return spans;
}

/// Renders [text] as tap-aware highlighted rich text via a plain
/// [Text.rich] — no selection of its own. Callers that need selection
/// either wrap this in a [SelectionArea] (see `DropCapHighlightableText`)
/// or use [HighlightableText], which pairs the same span builder with
/// [SelectableText.rich].
///
/// Existing highlights show as tinted spans; tapping one opens the
/// color/edit-note/remove popover.
class HighlightableRichText extends StatefulWidget {
  const HighlightableRichText({
    required this.text,
    required this.field,
    required this.baseStyle,
    this.textAlign = TextAlign.left,
    this.textScaler,
    this.prefixText,
    this.offset = 0,
    this.scrollAnchorHighlight,
    this.scrollAnchorKey,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    super.key,
  });

  final String text;
  final HighlightField field;
  final TextStyle baseStyle;
  final TextAlign textAlign;
  final TextScaler? textScaler;

  /// Rendered ahead of [text] but excluded from highlighting/offsets.
  final String? prefixText;

  /// Shift applied when mapping stored highlight offsets into the
  /// substring rendered here — for use when the field's addressable text
  /// is split across sibling widgets (e.g. a drop cap letter and the two
  /// wrap regions beside/below it, each carrying its own [offset]).
  final int offset;

  final TextHighlight? scrollAnchorHighlight;
  final Key? scrollAnchorKey;

  final int? maxLines;
  final TextOverflow overflow;

  @override
  State<HighlightableRichText> createState() => _HighlightableRichTextState();
}

class _HighlightableRichTextState extends State<HighlightableRichText> {
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
              (h, details) => unawaited(
                showHighlightMenu(
                  context,
                  widget.field,
                  details.globalPosition,
                  h,
                ),
              ),
          recognizerSink: _recognizers,
          offset: widget.offset,
          scrollAnchorHighlight: widget.scrollAnchorHighlight,
          scrollAnchorKey: widget.scrollAnchorKey,
        ),
      ],
    );

    return Text.rich(
      span,
      textAlign: widget.textAlign,
      textScaler: widget.textScaler,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

/// Renders [text] as selectable, highlightable rich text for [field].
/// Selecting a range shows a color-swatch popup instead of the default
/// copy/paste toolbar; tapping an existing highlight reopens it with a
/// remove option.
///
/// For quote text that needs a drop cap, use `DropCapHighlightableText`
/// instead — it stitches together multiple [HighlightableRichText]s under
/// a single [SelectionArea] so a selection can span the wrap boundary.
class HighlightableText extends StatefulWidget {
  const HighlightableText({
    required this.text,
    required this.field,
    required this.baseStyle,
    this.textAlign = TextAlign.left,
    this.prefixText,
    this.selectionActiveNotifier,
    this.textScaler,
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
  final AddNoteBubbleHost _addNoteBubble = AddNoteBubbleHost();

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    _addNoteBubble.dismiss();
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
          resolveColor:
              (h) => context
                  .highlightColor(h.colorId)
                  .withValues(alpha: context.isDarkMode ? 0.42 : 0.62),
          onHighlightTapDown:
              (h, details) => unawaited(
                showHighlightMenu(
                  context,
                  widget.field,
                  details.globalPosition,
                  h,
                ),
              ),
          recognizerSink: _recognizers,
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

    final (fieldStart, fieldEnd) = snapToWordBoundaries(
      widget.text,
      contentStart,
      contentEnd,
    );

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
            final snippet = widget.text.substring(fieldStart, fieldEnd);
            final highlightId = generateHighlightId();
            context.read<HighlightCubit>().addHighlight(
              field: widget.field,
              start: fieldStart,
              end: fieldEnd,
              colorId: colorId,
              snippet: snippet,
              id: highlightId,
            );
            editableTextState
              ..hideToolbar()
              ..userUpdateTextEditingValue(
                editableTextState.textEditingValue.copyWith(
                  selection: TextSelection.collapsed(offset: selection.end),
                ),
                SelectionChangedCause.tap,
              );
            _addNoteBubble.show(
              toolbarContext: ctx,
              hostContext: context,
              anchors: anchors,
              field: widget.field,
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

/// Shared "Add note" pill that appears next to a highlight the moment it's
/// created, giving the user a chance to attach a note without the note
/// sheet grabbing focus (and the keyboard) unprompted. Owned by each
/// selection-handling State so its [OverlayEntry] and [Timer] get cleaned
/// up on unmount.
class AddNoteBubbleHost {
  OverlayEntry? _entry;
  Timer? _timer;
  static const _duration = Duration(seconds: 4);

  void show({
    required BuildContext toolbarContext,
    required BuildContext hostContext,
    required TextSelectionToolbarAnchors anchors,
    required HighlightField field,
    required TextHighlight highlight,
  }) {
    dismiss();
    final overlay = Overlay.of(toolbarContext);
    final entry = OverlayEntry(
      builder:
          (_) => TextSelectionToolbar(
            anchorAbove: anchors.primaryAnchor,
            anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
            children: [
              AddNoteBubble(
                onTap: () {
                  dismiss();
                  unawaited(showNoteDialog(hostContext, field, highlight));
                },
              ),
            ],
          ),
    );
    overlay.insert(entry);
    _entry = entry;
    _timer = Timer(_duration, dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

/// Opens the change-color / edit-note / remove menu for an existing
/// [highlight] anchored at [globalPosition] (typically the tap position on
/// the highlighted span itself).
Future<void> showHighlightMenu(
  BuildContext context,
  HighlightField field,
  Offset globalPosition,
  TextHighlight highlight,
) async {
  final overlayBox =
      Overlay.of(context).context.findRenderObject()! as RenderBox;
  await showMenu<void>(
    context: context,
    color: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(),
    position: RelativeRect.fromRect(
      globalPosition & const Size(1, 1),
      Offset.zero & overlayBox.size,
    ),
    items: [
      PopupMenuItem<void>(
        enabled: false,
        padding: EdgeInsets.zero,
        height: 0,
        child: HighlightColorToolbar(
          colorIds: context.highlightColorIds,
          selectedColorId: highlight.colorId,
          onColorSelected: (colorId) {
            context.read<HighlightCubit>().changeHighlightColor(
              field: field,
              highlight: highlight,
              newColorId: colorId,
            );
            Navigator.of(context).pop();
          },
          onRemove: () {
            context.read<HighlightCubit>().removeHighlight(
              field: field,
              highlight: highlight,
            );
            Navigator.of(context).pop();
          },
          onEditNote: () {
            Navigator.of(context).pop();
            unawaited(showNoteDialog(context, field, highlight));
          },
        ),
      ),
    ],
  );
}

/// Opens the note bottom sheet for [highlight] and persists the trimmed
/// result (or clears the note if empty) via [HighlightCubit.setNote].
Future<void> showNoteDialog(
  BuildContext context,
  HighlightField field,
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
      field: field,
      highlight: highlight,
      note: trimmed.isEmpty ? null : trimmed,
    ),
  );
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

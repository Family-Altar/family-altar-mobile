import 'package:family_altar/screens/highlights/widgets/field_chip.dart';
import 'package:family_altar/screens/reader/cubit/highlight_cubit.dart';
import 'package:family_altar/screens/reader/domain/reader_route_args.dart';
import 'package:family_altar/screens/reader/widgets/highlight_color_toolbar.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/utils/utilities.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HighlightTile extends StatelessWidget {
  const HighlightTile({
    required this.entry,
    required this.onColorSelected,
    required this.onRemove,
    required this.onEditNote,
    super.key,
  });

  final HighlightListEntry entry;
  final ValueChanged<String> onColorSelected;
  final VoidCallback onRemove;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final note = entry.highlight.note;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.calendarCellBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push(
              '/reader',
              extra: ReaderRouteArgs(
                date: entry.date,
                scrollTarget: HighlightScrollTarget(
                  field: entry.field,
                  highlight: entry.highlight,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: context.highlightColor(entry.highlight.colorId),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              formatDateTypeToDDMM(entry.date),
                              style: AppFonts.bold(
                                context,
                                size: FontSize.small,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FieldChip(label: entry.field.displayLabel),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '“${entry.highlight.snippet}”',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.normal(context),
                        ),
                        if (note != null && note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.edit_note,
                                size: 16,
                                color: context.calendarDayTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  note,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.italics(
                                    context,
                                    size: FontSize.small,
                                  ).copyWith(
                                    color: context.calendarDayTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Center(
                  child: PopupMenuButton<void>(
                    icon: Icon(
                      Icons.more_vert,
                      color: context.calendarDayTextSecondary,
                    ),
                    tooltip: 'Edit highlight',
                    color: context.dialogBG,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    itemBuilder:
                        (menuContext) => [
                          PopupMenuItem<void>(
                            enabled: false,
                            padding: EdgeInsets.zero,
                            child: HighlightColorToolbar(
                              colorIds: menuContext.highlightColorIds,
                              selectedColorId: entry.highlight.colorId,
                              onColorSelected: (colorId) {
                                Navigator.of(menuContext).pop();
                                onColorSelected(colorId);
                              },
                              onRemove: () {
                                Navigator.of(menuContext).pop();
                                onRemove();
                              },
                              onEditNote: () {
                                Navigator.of(menuContext).pop();
                                onEditNote();
                              },
                            ),
                          ),
                        ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Icon(
                      Icons.chevron_right,
                      color: context.calendarDayTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

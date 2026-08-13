import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/screens/reader/cubit/highlight_cubit.dart';
import 'package:family_altar/screens/reader/domain/reader_route_args.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/utils/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HighlightsListScreen extends StatefulWidget {
  const HighlightsListScreen({super.key});

  @override
  State<HighlightsListScreen> createState() => _HighlightsListScreenState();
}

class _HighlightsListScreenState extends State<HighlightsListScreen> {
  late final Future<List<HighlightListEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    final volume = context.read<ReadingBloc>().currentVolume;
    _entriesFuture = loadAllHighlights(volume);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.textColor),
            onPressed: () => context.pop(),
          ),
          title: Text('My Highlights', style: AppFonts.bold(context)),
        ),
        body: FutureBuilder<List<HighlightListEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final entries = snapshot.data ?? const [];
            if (entries.isEmpty) {
              return _buildEmptyState(context);
            }

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _HighlightTile(entry: entries[index]),
                      childCount: entries.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: context.calendarDayTextSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No highlights yet',
              style: AppFonts.bold(context, size: FontSize.large),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Select text in a daily reading to highlight it.',
              style: AppFonts.normal(
                context,
                size: FontSize.small,
              ).copyWith(color: context.calendarDayTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.entry});

  final HighlightListEntry entry;

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
                              formatDateTypeToDDMMYYY(entry.date),
                              style: AppFonts.bold(
                                context,
                                size: FontSize.small,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FieldChip(label: entry.field.displayLabel),
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

class _FieldChip extends StatelessWidget {
  const _FieldChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.missedDaysBadgeBG,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppFonts.normal(
          context,
          size: FontSize.small,
        ).copyWith(color: context.missedDaysBadgeText, fontSize: 11),
      ),
    );
  }
}

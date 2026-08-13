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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  final Set<String> _selectedColorIds = {};

  @override
  void initState() {
    super.initState();
    final volume = context.read<ReadingBloc>().currentVolume;
    _entriesFuture = loadAllHighlights(volume);
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _dateRange != null ||
      _selectedColorIds.isNotEmpty;

  List<HighlightListEntry> _applyFilters(List<HighlightListEntry> entries) {
    return entries.where((entry) {
      if (_selectedColorIds.isNotEmpty &&
          !_selectedColorIds.contains(entry.highlight.colorId)) {
        return false;
      }

      if (_dateRange != null) {
        final date = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        final start = _dateRange!.start;
        final end = _dateRange!.end;
        if (date.isBefore(DateTime(start.year, start.month, start.day)) ||
            date.isAfter(DateTime(end.year, end.month, end.day))) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final snippet = entry.highlight.snippet.toLowerCase();
        final note = (entry.highlight.note ?? '').toLowerCase();
        if (!snippet.contains(_searchQuery) && !note.contains(_searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _toggleColor(String colorId) {
    setState(() {
      if (!_selectedColorIds.remove(colorId)) {
        _selectedColorIds.add(colorId);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _dateRange = null;
      _selectedColorIds.clear();
    });
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
          actions: [
            if (_hasActiveFilters)
              IconButton(
                icon: Icon(Icons.filter_alt_off, color: context.textColor),
                tooltip: 'Clear filters',
                onPressed: _clearFilters,
              ),
          ],
        ),
        body: FutureBuilder<List<HighlightListEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final allEntries = snapshot.data ?? const [];
            if (allEntries.isEmpty) {
              return _buildEmptyState(context);
            }

            final filtered = _applyFilters(allEntries);

            return Column(
              children: [
                _FilterBar(
                  searchController: _searchController,
                  dateRange: _dateRange,
                  onPickDateRange: _pickDateRange,
                  onClearDateRange: () => setState(() => _dateRange = null),
                  selectedColorIds: _selectedColorIds,
                  onToggleColor: _toggleColor,
                ),
                Expanded(
                  child:
                      filtered.isEmpty
                          ? _buildNoMatchesState(context)
                          : CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  24,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) =>
                                        _HighlightTile(entry: filtered[index]),
                                    childCount: filtered.length,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildNoMatchesState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: context.calendarDayTextSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No highlights match your filters',
              style: AppFonts.bold(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.dateRange,
    required this.onPickDateRange,
    required this.onClearDateRange,
    required this.selectedColorIds,
    required this.onToggleColor,
  });

  final TextEditingController searchController;
  final DateTimeRange? dateRange;
  final VoidCallback onPickDateRange;
  final VoidCallback onClearDateRange;
  final Set<String> selectedColorIds;
  final ValueChanged<String> onToggleColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            style: AppFonts.normal(context),
            decoration: InputDecoration(
              hintText: 'Search highlights and notes',
              hintStyle: AppFonts.normal(
                context,
              ).copyWith(color: context.textColor.withValues(alpha: 0.4)),
              prefixIcon: Icon(
                Icons.search,
                color: context.textColor.withValues(alpha: 0.6),
              ),
              suffixIcon:
                  searchController.text.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 18,
                          color: context.textColor.withValues(alpha: 0.6),
                        ),
                        onPressed: searchController.clear,
                      )
                      : null,
              filled: true,
              fillColor: context.accent.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          _DateRangeChip(
            dateRange: dateRange,
            onTap: onPickDateRange,
            onClear: dateRange != null ? onClearDateRange : null,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final colorId in context.highlightColorIds)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ColorFilterDot(
                      colorId: colorId,
                      isSelected: selectedColorIds.contains(colorId),
                      onTap: () => onToggleColor(colorId),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({
    required this.dateRange,
    required this.onTap,
    this.onClear,
  });

  final DateTimeRange? dateRange;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final isActive = dateRange != null;
    final label =
        isActive
            ? '${formatDateTypeToDDMMYYY(dateRange!.start)} – '
                '${formatDateTypeToDDMMYYY(dateRange!.end)}'
            : 'Date range';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? context.accent.withValues(alpha: 0.12)
                  : context.accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, size: 16, color: context.textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.normal(
                context,
                size: FontSize.small,
              ).copyWith(fontWeight: isActive ? FontWeight.bold : null),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: context.textColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColorFilterDot extends StatelessWidget {
  const _ColorFilterDot({
    required this.colorId,
    required this.isSelected,
    required this.onTap,
  });

  final String colorId;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.highlightColor(colorId);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? context.textColor : Colors.transparent,
            width: 2,
          ),
        ),
        child:
            isSelected
                ? Icon(
                  Icons.check,
                  size: 14,
                  color:
                      ThemeData.estimateBrightnessForColor(color) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                )
                : null,
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

import 'package:family_altar/models/volume.dart';
import 'package:family_altar/screens/highlights/widgets/filter_bar.dart';
import 'package:family_altar/screens/highlights/widgets/highlight_tile.dart';
import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/screens/reader/cubit/highlight_cubit.dart';
import 'package:family_altar/screens/reader/domain/text_highlight.dart';
import 'package:family_altar/screens/reader/widgets/highlightable_text.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HighlightsListScreen extends StatefulWidget {
  const HighlightsListScreen({super.key});

  @override
  State<HighlightsListScreen> createState() => _HighlightsListScreenState();
}

class _HighlightsListScreenState extends State<HighlightsListScreen> {
  late final Volume _volume;
  List<HighlightListEntry>? _allEntries;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  final Set<String> _selectedColorIds = {};

  @override
  void initState() {
    super.initState();
    _volume = context.read<ReadingBloc>().currentVolume;
    _loadEntries();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  Future<void> _loadEntries() async {
    final entries = await loadAllHighlights(_volume);
    if (!mounted) return;
    setState(() => _allEntries = entries);
  }

  Future<void> _deleteEntry(HighlightListEntry entry) async {
    await removeHighlightEntry(_volume, entry);
    if (!mounted) return;
    setState(() {
      _allEntries =
          _allEntries
              ?.where((e) => !_sameHighlight(e, entry))
              .toList();
    });
  }

  Future<void> _changeColor(HighlightListEntry entry, String colorId) async {
    await changeHighlightEntryColor(_volume, entry, colorId);
    if (!mounted) return;
    setState(() {
      _allEntries = _replaceHighlight(
        entry,
        TextHighlight(
          id: entry.highlight.id,
          start: entry.highlight.start,
          end: entry.highlight.end,
          colorId: colorId,
          snippet: entry.highlight.snippet,
          note: entry.highlight.note,
        ),
      );
    });
  }

  Future<void> _editNote(HighlightListEntry entry) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => NoteSheet(initialNote: entry.highlight.note),
    );
    if (result == null || !mounted) return;

    final trimmed = result.trim();
    final note = trimmed.isEmpty ? null : trimmed;
    await setHighlightEntryNote(_volume, entry, note);
    if (!mounted) return;
    setState(() {
      _allEntries = _replaceHighlight(
        entry,
        TextHighlight(
          id: entry.highlight.id,
          start: entry.highlight.start,
          end: entry.highlight.end,
          colorId: entry.highlight.colorId,
          snippet: entry.highlight.snippet,
          note: note,
        ),
      );
    });
  }

  // Ids are only guaranteed unique within a single date+field's highlight
  // list (legacy highlights predating ids fall back to a start/end/color
  // derived id, which isn't globally unique), so scope the lookup to match.
  bool _sameHighlight(HighlightListEntry a, HighlightListEntry b) =>
      a.date == b.date &&
      a.field == b.field &&
      a.highlight.id == b.highlight.id;

  List<HighlightListEntry>? _replaceHighlight(
    HighlightListEntry entry,
    TextHighlight updated,
  ) {
    return _allEntries
        ?.map(
          (e) =>
              _sameHighlight(e, entry)
                  ? HighlightListEntry(
                    date: e.date,
                    field: e.field,
                    highlight: updated,
                  )
                  : e,
        )
        .toList();
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: context.backgroundColor,
            title: Text(
              'Clear All Highlights',
              style: AppFonts.bold(context, size: FontSize.large),
            ),
            content: Text(
              'Are you sure you want to delete all your highlights and '
              "notes? This can't be undone.",
              style: AppFonts.normal(context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: AppFonts.normal(
                    context,
                  ).copyWith(color: context.textColor),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(
                  'Delete all',
                  style: AppFonts.normal(
                    context,
                  ).copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    await clearAllHighlights(_volume);
    if (!mounted) return;
    setState(() => _allEntries = []);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All highlights cleared',
          style: AppFonts.normal(context),
        ),
        backgroundColor: context.backgroundColor.withValues(alpha: 0.8),
      ),
    );
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
          title: Text(
            '${_volume.displayTitle} Highlights',
            style: AppFonts.bold(context),
          ),
          actions: [
            if (_allEntries != null && _allEntries!.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  color: context.textColor,
                ),
                tooltip: 'Clear all highlights',
                onPressed: _confirmClearAll,
              ),
            if (_hasActiveFilters)
              IconButton(
                icon: Icon(Icons.filter_alt_off, color: context.textColor),
                tooltip: 'Clear filters',
                onPressed: _clearFilters,
              ),
          ],
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final allEntries = _allEntries;
    if (allEntries == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (allEntries.isEmpty) {
      return _buildEmptyState(context);
    }

    final filtered = _applyFilters(allEntries);

    return Column(
      children: [
        FilterBar(
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => HighlightTile(
                              entry: filtered[index],
                              onColorSelected:
                                  (colorId) =>
                                      _changeColor(filtered[index], colorId),
                              onRemove: () => _deleteEntry(filtered[index]),
                              onEditNote: () => _editNote(filtered[index]),
                            ),
                            childCount: filtered.length,
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ],
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


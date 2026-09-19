import 'package:family_altar/screens/highlights/widgets/color_filter_dot.dart';
import 'package:family_altar/screens/highlights/widgets/date_range_chip.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    required this.searchController,
    required this.dateRange,
    required this.onPickDateRange,
    required this.onClearDateRange,
    required this.selectedColorIds,
    required this.onToggleColor,
    super.key,
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
          DateRangeChip(
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
                    child: ColorFilterDot(
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

import 'package:family_altar/models/reading_entry.dart';
import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MissedDaysScreen extends StatelessWidget {
  const MissedDaysScreen({
    required this.volumeId,
    super.key,
  });

  final String volumeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          '${_volumeTitle(volumeId)} · Missed Days',
          style: AppFonts.bold(context),
        ),
      ),
      body: BlocBuilder<ReadingBloc, ReadingState>(
        builder: (context, state) {
          final loadedState = state is ReadingLoaded ? state : null;
          final missedList = loadedState != null
              ? (List<ReadingEntry>.from(loadedState.getMissedEntries())
                ..sort((a, b) => a.date.compareTo(b.date)))
              : <ReadingEntry>[];

          if (missedList.isEmpty) {
            return _buildEmptyState(context);
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${missedList.length} '
                        '${missedList.length == 1 ? 'day' : 'days'} to catch up',
                        style: AppFonts.normal(
                          context,
                          size: FontSize.small,
                        ).copyWith(color: context.calendarDayTextSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to open that day’s reading.',
                        style: AppFonts.normal(
                          context,
                          size: FontSize.small,
                        ).copyWith(
                          color: context.calendarDayTextSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = missedList[index];
                      final normalizedDate = DateTime(
                        entry.date.year,
                        entry.date.month,
                        entry.date.day,
                      );
                      final normalizedFirst = DateTime(
                        loadedState!.firstLaunchDate.year,
                        loadedState.firstLaunchDate.month,
                        loadedState.firstLaunchDate.day,
                      );
                      final dayNumber =
                          normalizedDate.difference(normalizedFirst).inDays + 1;
                      return _MissedDayTile(
                        entry: entry,
                        dayNumber: dayNumber,
                        onTap: () {
                          context.push('/reader', extra: entry.date);
                        },
                      );
                    },
                    childCount: missedList.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
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
              Icons.check_circle_outline,
              size: 80,
              color: AppColors.calendarCompletedIcon.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 24),
            Text(
              "You're all caught up!",
              style: AppFonts.bold(context, size: FontSize.large),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'No missed days. Keep up the great reading.',
              style: AppFonts.normal(context, size: FontSize.small).copyWith(
                color: context.calendarDayTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _volumeTitle(String volumeId) {
  switch (volumeId) {
    case '1':
      return 'Volume I';
    case '2':
      return 'Volume II';
    case '3':
      return 'Volume III';
    default:
      return 'Volume $volumeId';
  }
}

class _MissedDayTile extends StatelessWidget {
  const _MissedDayTile({
    required this.entry,
    required this.dayNumber,
    required this.onTap,
  });

  final ReadingEntry entry;
  final int dayNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.calendarMissedBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Day $dayNumber',
                    style: AppFonts.bold(context, size: FontSize.small),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: context.calendarDayTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

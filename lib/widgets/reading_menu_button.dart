import 'package:family_altar/models/volume.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/widgets/reading_settings_bottom_sheet.dart';
import 'package:flutter/material.dart';

enum _MenuAction { share, highlights, settings }

/// The "more" menu shared by the reader and foreword/preface app bars:
/// volume selection, share, highlights, and font/theme settings.
class ReadingMenuButton extends StatelessWidget {
  const ReadingMenuButton({
    required this.currentVolume,
    required this.onVolumeSelected,
    required this.shareLabel,
    required this.onShare,
    required this.onHighlights,
    super.key,
  });

  final Volume currentVolume;

  /// Called only when a volume other than [currentVolume] is chosen.
  final ValueChanged<Volume> onVolumeSelected;
  final String shareLabel;
  final VoidCallback onShare;
  final VoidCallback onHighlights;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Object>(
      color: context.backgroundColor,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[800],
        ),
        child: CircleAvatar(
          radius: 12,
          backgroundColor: context.backgroundColor,
          child: Icon(Icons.more_horiz, color: context.textColor, size: 20),
        ),
      ),
      onSelected: (value) {
        switch (value) {
          case final Volume volume when volume != currentVolume:
            onVolumeSelected(volume);
          case _MenuAction.share:
            onShare();
          case _MenuAction.highlights:
            onHighlights();
          case _MenuAction.settings:
            showReadingSettingsBottomSheet(context);
        }
      },
      itemBuilder:
          (context) => [
            for (final volume in Volume.values)
              _item(
                context,
                value: volume,
                icon: volume == currentVolume ? Icons.check : null,
                label: volume.displayTitle,
              ),
            const PopupMenuDivider(),
            _item(
              context,
              value: _MenuAction.share,
              icon: Icons.share,
              label: shareLabel,
            ),
            _item(
              context,
              value: _MenuAction.highlights,
              icon: Icons.bookmark_border,
              label: '${currentVolume.displayTitle} Highlights',
            ),
            _item(
              context,
              value: _MenuAction.settings,
              icon: Icons.settings,
              label: 'Font and Settings',
            ),
          ],
    );
  }

  PopupMenuItem<Object> _item(
    BuildContext context, {
    required Object value,
    required IconData? icon,
    required String label,
  }) {
    return PopupMenuItem<Object>(
      value: value,
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, color: context.textColor, size: 20)
          else
            const SizedBox(width: 20),
          const SizedBox(width: 12),
          Text(label, style: AppFonts.normal(context)),
        ],
      ),
    );
  }
}

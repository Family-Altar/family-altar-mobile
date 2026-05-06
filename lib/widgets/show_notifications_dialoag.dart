import 'package:family_altar/widgets/reading_settings_bottom_sheet.dart';
import 'package:flutter/material.dart';

/// Shows reading settings in a centered popup dialog.
void show_notifications_dialoag(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder:
        (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: const ReadingSettingsBottomSheet(),
        ),
  );
}

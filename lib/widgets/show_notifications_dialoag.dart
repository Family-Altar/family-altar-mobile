import 'package:family_altar/widgets/reading_settings_bottom_sheet.dart';
import 'package:flutter/material.dart';

/// Shows reading settings in a centered popup dialog.
void showNotificationsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder:
        (_) => const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ReadingSettingsBottomSheet(),
        ),
  );
}

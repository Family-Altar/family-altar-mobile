import 'package:family_altar/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum Volume {
  one,
  two,
  three;

  String get assetBasePath => switch (this) {
    Volume.one => 'assets/volume_I',
    Volume.two => 'assets/volume_II',
    Volume.three => 'assets/volume_III',
  };

  // Empty suffix preserves existing SharedPreferences keys for Volume I.
  // Volume II appends '_v2' to namespace its keys separately.
  String get storageSuffix => switch (this) {
    Volume.one => '',
    Volume.two => '_v2',
    Volume.three => '_v3',
  };

  String get displayTitle => switch (this) {
    Volume.one => 'Volume I',
    Volume.two => 'Volume II',
    Volume.three => 'Volume III',
  };

  String get volumeId => switch (this) {
    Volume.one => '1',
    Volume.two => '2',
    Volume.three => '3',
  };

  String get bannerImagePath => switch (this) {
    Volume.one => 'assets/images/FamilyAltarVolumeIImage.png',
    Volume.two => 'assets/images/FamilyAltarVolumeIIImage.jpg',
    Volume.three => 'assets/images/FamilyAltarVolumeIIIImage.jpg',
  };

  // Where in the image the focal subject sits (0 = top, 1 = bottom).
  double get bannerFocalY => switch (this) {
    Volume.one => 0.5,
    Volume.two => 0.6,
    Volume.three => 0.3,
  };

  // Where in the visible banner to place the focal point (0 = top, 1 = bottom).
  double get bannerTargetY => switch (this) {
    Volume.one => 0.7,
    Volume.two => 0.3,
    Volume.three => 0.5,
  };

  // imageWidth / imageHeight for the banner image asset.
  double get bannerAspectRatio => switch (this) {
    Volume.one => 3 / 4,
    Volume.two => 3 / 4,
    Volume.three => 3 / 4,
  };

  Color appBarColor({required bool isDark}) => switch (this) {
    Volume.one => isDark ? AppColors.darkSurface : AppColors.lightAppBar,
    Volume.two =>
      isDark ? AppColors.darkSurfaceVolumeII : AppColors.lightAppBarVolumeII,
    Volume.three =>
      isDark ? AppColors.darkSurfaceVolumeIII : AppColors.lightAppBarVolumeIII,
  };
}

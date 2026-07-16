enum Volume {
  one,
  two;

  String get assetBasePath => switch (this) {
        Volume.one => 'assets/volume_I',
        Volume.two => 'assets/volume_II',
      };

  // Empty suffix preserves existing SharedPreferences keys for Volume I.
  // Volume II appends '_v2' to namespace its keys separately.
  String get storageSuffix => switch (this) {
        Volume.one => '',
        Volume.two => '_v2',
      };

  String get displayTitle => switch (this) {
        Volume.one => 'Volume I',
        Volume.two => 'Volume II',
      };

  String get volumeId => switch (this) {
        Volume.one => '1',
        Volume.two => '2',
      };
}

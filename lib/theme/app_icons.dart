class AppIcons {
  AppIcons._();
  static double getIconSize(IconSize size) {
    switch (size) {
      case IconSize.small:
        return 16;
      case IconSize.medium:
        return 20;
      case IconSize.large:
        return 24;
      case IconSize.extraLarge:
        return 32;
    }
  }
}
enum IconSize {
  small,
  medium,
  large,
  extraLarge,
}


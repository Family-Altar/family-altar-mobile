class Utils {
  static DateTime fromDayToDate(int dayOfYear, int year) {
    final firstDayOfYear = DateTime(year);
    return firstDayOfYear.add(Duration(days: dayOfYear - 1));
  }

  /// Convert a DateTime to its day-of-year number (1–366).
  /// Example: Jan 1 -> 1, Feb 1 -> 32
  static int fromDateToDay(DateTime date) {
    final firstDayOfYear = DateTime(date.year);
    return date.difference(firstDayOfYear).inDays + 1;
  }

  static int getTotalDays() {
    final now = DateTime.now();
    final year = now.year;
    // Check if it's a leap year
    final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    return isLeapYear ? 366 : 365;
  }
}

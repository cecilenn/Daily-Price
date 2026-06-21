import 'package:intl/intl.dart';

class AssetInputParser {
  const AssetInputParser._();

  static int parseExpectedDays(String input) {
    if (input.isEmpty) return 0;

    final trimmed = input.trim();
    final pureNumberPattern = RegExp(r'^\s*(\d+)\s*$');
    final pureMatch = pureNumberPattern.firstMatch(trimmed);
    if (pureMatch != null) {
      return int.parse(pureMatch.group(1)!);
    }

    final yearPattern = RegExp(r'(\d+)\s*年');
    final monthPattern = RegExp(r'(\d+)\s*(?:个\s*)?月');
    final dayPattern = RegExp(r'(\d+)\s*天');

    final yearMatch = yearPattern.firstMatch(trimmed);
    final monthMatch = monthPattern.firstMatch(trimmed);
    final dayMatch = dayPattern.firstMatch(trimmed);

    var totalDays = 0;
    var hasMatch = false;

    if (yearMatch != null) {
      totalDays += int.parse(yearMatch.group(1)!) * 365;
      hasMatch = true;
    }

    if (monthMatch != null) {
      totalDays += int.parse(monthMatch.group(1)!) * 30;
      hasMatch = true;
    }

    if (dayMatch != null) {
      totalDays += int.parse(dayMatch.group(1)!);
      hasMatch = true;
    }

    return hasMatch ? totalDays : 0;
  }

  static DateTime? parseCustomDate(String input) {
    if (input.isEmpty) return null;

    final trimmed = input.trim();
    var normalized = trimmed;

    if (normalized.contains('年') ||
        normalized.contains('月') ||
        normalized.contains('日')) {
      normalized = normalized.replaceAll(RegExp(r'\s+'), '');
      normalized = normalized.replaceAll('年', '-');
      normalized = normalized.replaceAll('月', '-');
      normalized = normalized.replaceAll('日', '');
      normalized = normalized.replaceAll(RegExp(r'-+$'), '');
    }

    final dashMatch = RegExp(
      r'^(\d{4})-(\d{1,2})-(\d{1,2})$',
    ).firstMatch(normalized);
    if (dashMatch != null) {
      return _buildDate(
        dashMatch.group(1)!,
        dashMatch.group(2)!,
        dashMatch.group(3)!,
      );
    }

    final dotMatch = RegExp(
      r'^(\d{4})\.(\d{1,2})\.(\d{1,2})$',
    ).firstMatch(trimmed);
    if (dotMatch != null) {
      return _buildDate(
        dotMatch.group(1)!,
        dotMatch.group(2)!,
        dotMatch.group(3)!,
      );
    }

    final slashMatch = RegExp(
      r'^(\d{4})/(\d{1,2})/(\d{1,2})$',
    ).firstMatch(trimmed);
    if (slashMatch != null) {
      return _buildDate(
        slashMatch.group(1)!,
        slashMatch.group(2)!,
        slashMatch.group(3)!,
      );
    }

    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    return DateFormat(format).format(date);
  }

  static String formatDays(int days, {String style = 'combined'}) {
    if (style == 'days') {
      return '$days 天';
    }

    final years = days ~/ 365;
    final remainingAfterYears = days % 365;
    final months = remainingAfterYears ~/ 30;
    final remainingDays = remainingAfterYears % 30;

    final parts = <String>[];
    if (years > 0) parts.add('$years 年');
    if (months > 0) parts.add('$months 月');
    if (remainingDays > 0) parts.add('$remainingDays 天');

    if (parts.isEmpty) return '0 天';
    return parts.join('');
  }

  static DateTime? _buildDate(String year, String month, String day) {
    try {
      return DateTime(int.parse(year), int.parse(month), int.parse(day));
    } catch (_) {
      return null;
    }
  }
}

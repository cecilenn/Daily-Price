/// 时长显示格式化工具
class TimeFormatter {
  /// 格式化天数为可读字符串
  ///
  /// [totalDays] 总天数
  /// [mode] 显示模式：
  ///   - 'auto'：自动计算，如 "1年3月15天"（默认）
  ///   - 'smart'：自动合并，选最合适的单位，如 "1.3年"
  ///   - 'year'：强制年，如 "1.3年"
  ///   - 'month'：强制月，如 "15.5月"
  ///   - 'day'：强制天，如 "465天"
  static String formatDays(int totalDays, {String mode = 'auto'}) {
    if (totalDays <= 0) return '0天';

    switch (mode) {
      case 'auto':
        return _formatAuto(totalDays);
      case 'smart':
        return _formatSmart(totalDays);
      case 'year':
        return '${(totalDays / 365).toStringAsFixed(1)}年';
      case 'month':
        return '${(totalDays / 30).round()}月';
      case 'day':
        return '${totalDays}天';
      default:
        return '${totalDays}天';
    }
  }

  /// 自动计算："1年3月15天"
  static String _formatAuto(int totalDays) {
    final years = totalDays ~/ 365;
    final months = (totalDays % 365) ~/ 30;
    final days = (totalDays % 365) % 30;

    final parts = <String>[];
    if (years > 0) parts.add('${years}年');
    if (months > 0) parts.add('${months}月');
    if (days > 0 || parts.isEmpty) parts.add('${days}天');
    return parts.join();
  }

  /// 智能合并：选最合适的一个单位
  static String _formatSmart(int totalDays) {
    if (totalDays >= 365) return '${(totalDays / 365).toStringAsFixed(1)}年';
    if (totalDays >= 30) return '${(totalDays / 30).round()}月';
    return '${totalDays}天';
  }
}

import 'package:intl/intl.dart';

/// 资产模型 - 用于记录个人资产折旧与价值平摊
/// 数据库字段对应：
/// - id: UUID 主键
/// - asset_name: 资产名称
/// - purchase_price: 购入价格
/// - expected_lifespan_days: 预计使用天数
/// - purchase_date: 购买日期
/// - is_pinned: 是否置顶
/// - is_sold: 是否已出售
/// - sold_price: 出售价格
/// - sold_date: 出售日期
/// - created_at: 创建时间
class Asset {
  final String? id;
  final String assetName; // 资产名称
  final double purchasePrice; // 购入价格
  final int expectedLifespanDays; // 预计使用天数
  final DateTime purchaseDate; // 购买日期
  final bool isPinned; // 是否置顶
  final bool isSold; // 是否已出售
  final double? soldPrice; // 出售价格
  final DateTime? soldDate; // 出售日期
  final DateTime createdAt; // 创建时间

  Asset({
    this.id,
    required this.assetName,
    required this.purchasePrice,
    required this.expectedLifespanDays,
    required this.purchaseDate,
    this.isPinned = false,
    this.isSold = false,
    this.soldPrice,
    this.soldDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 计算日均成本
  double get dailyCost {
    if (expectedLifespanDays <= 0) return 0;
    return purchasePrice / expectedLifespanDays;
  }

  /// 计算剩余天数
  int get remainingDays {
    final endDate = purchaseDate.add(Duration(days: expectedLifespanDays));
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  /// 计算已使用天数
  int get usedDays {
    final now = DateTime.now();
    final difference = now.difference(purchaseDate).inDays;
    return difference > 0 ? difference : 0;
  }

  /// 计算实际使用天数（如果已出售，则计算到出售日期）
  int get actualUsedDays {
    if (isSold && soldDate != null) {
      final difference = soldDate!.difference(purchaseDate).inDays;
      return difference > 0 ? difference : 0;
    }
    return usedDays;
  }

  /// 计算剩余价值
  double get remainingValue {
    if (isSold) return 0;
    if (expectedLifespanDays <= 0) return 0;
    return dailyCost * remainingDays;
  }

  /// 计算已折旧金额
  double get depreciatedValue {
    if (expectedLifespanDays <= 0) return purchasePrice;
    return dailyCost * actualUsedDays;
  }

  /// 是否已过期（超过预计使用天数）
  bool get isExpired => remainingDays == 0;

  /// 计算实际日均花费（考虑出售）
  /// 公式：(原购入价 - 卖出价格) / (出售日期 - 购买日期) 的天数
  double get actualDailyCost {
    if (isSold && soldPrice != null && soldDate != null) {
      final days = soldDate!.difference(purchaseDate).inDays;
      if (days <= 0) return 0;
      return (purchasePrice - soldPrice!) / days;
    }
    return dailyCost;
  }

  /// 计算出售盈亏
  double get soldProfitOrLoss {
    if (!isSold || soldPrice == null) return 0;
    return soldPrice! - (purchasePrice - depreciatedValue);
  }

  /// 转换为 JSON（用于数据库插入/更新）
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'asset_name': assetName,
      'purchase_price': purchasePrice,
      'expected_lifespan_days': expectedLifespanDays,
      'purchase_date': purchaseDate.toIso8601String(),
      'is_pinned': isPinned,
      'is_sold': isSold,
      if (soldPrice != null) 'sold_price': soldPrice,
      if (soldDate != null) 'sold_date': soldDate!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 从 JSON 创建 Asset 对象（用于数据库查询结果）
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String?,
      assetName: json['asset_name'] as String,
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      expectedLifespanDays: json['expected_lifespan_days'] as int,
      purchaseDate: _parseDate(json['purchase_date']),
      isPinned: (json['is_pinned'] as bool?) ?? false,
      isSold: (json['is_sold'] as bool?) ?? false,
      soldPrice: json['sold_price'] != null ? (json['sold_price'] as num).toDouble() : null,
      soldDate: json['sold_date'] != null ? _parseDate(json['sold_date']) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 复制并修改
  Asset copyWith({
    String? id,
    String? assetName,
    double? purchasePrice,
    int? expectedLifespanDays,
    DateTime? purchaseDate,
    bool? isPinned,
    bool? isSold,
    double? soldPrice,
    DateTime? soldDate,
  }) {
    return Asset(
      id: id ?? this.id,
      assetName: assetName ?? this.assetName,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      expectedLifespanDays: expectedLifespanDays ?? this.expectedLifespanDays,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isPinned: isPinned ?? this.isPinned,
      isSold: isSold ?? this.isSold,
      soldPrice: soldPrice ?? this.soldPrice,
      soldDate: soldDate ?? this.soldDate,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'Asset(id: $id, assetName: $assetName, purchasePrice: $purchasePrice, expectedLifespanDays: $expectedLifespanDays, purchaseDate: $purchaseDate, isPinned: $isPinned, isSold: $isSold, soldPrice: $soldPrice, soldDate: $soldDate)';
  }

  /// 解析预计使用天数，支持自然语言
  /// 支持格式：
  /// - 纯数字：默认为天数
  /// - "1 年 6 个月"
  /// - "3 年"
  /// - "6 个月"
  /// - "100 天"
  /// - "1 年 6 个月 10 天"
  static int parseExpectedDays(String input) {
    if (input.isEmpty) return 0;
    
    final trimmed = input.trim();
    
    // 尝试纯数字（天数）
    final pureNumberPattern = RegExp(r'^(\d+)$');
    final pureMatch = pureNumberPattern.firstMatch(trimmed);
    if (pureMatch != null) {
      return int.parse(pureMatch.group(1)!);
    }
    
    // 尝试解析自然语言格式
    final yearPattern = RegExp(r'(\d+) 年');
    final monthPattern = RegExp(r'(\d+) 个？月');
    final dayPattern = RegExp(r'(\d+) 天');
    
    final yearMatch = yearPattern.firstMatch(trimmed);
    final monthMatch = monthPattern.firstMatch(trimmed);
    final dayMatch = dayPattern.firstMatch(trimmed);
    
    int totalDays = 0;
    
    if (yearMatch != null) {
      totalDays += int.parse(yearMatch.group(1)!) * 365;
    }
    
    if (monthMatch != null) {
      totalDays += int.parse(monthMatch.group(1)!) * 30;
    }
    
    if (dayMatch != null) {
      totalDays += int.parse(dayMatch.group(1)!);
    }
    
    // 如果没有匹配到任何有效格式，返回 0
    if (totalDays == 0 && yearMatch == null && monthMatch == null && dayMatch == null) {
      return 0;
    }
    
    return totalDays;
  }

  /// 解析自定义日期格式，支持手写输入
  /// 支持格式：
  /// - "2026 年 4 月 5 日"
  /// - "2025.2.3"
  /// - "2026-01-01"
  /// - "2026/01/01"
  /// - "2026-01-01 12:30:00"
  static DateTime? parseCustomDate(String input) {
    if (input.isEmpty) return null;
    
    final trimmed = input.trim();
    
    // 尝试解析中文格式 "2026 年 4 月 5 日"
    final chinesePattern = RegExp(r'(\d{4}) 年 (\d{1,2}) 月 (\d{1,2}) 日');
    final chineseMatch = chinesePattern.firstMatch(trimmed);
    if (chineseMatch != null) {
      final year = int.parse(chineseMatch.group(1)!);
      final month = int.parse(chineseMatch.group(2)!);
      final day = int.parse(chineseMatch.group(3)!);
      return DateTime(year, month, day);
    }
    
    // 尝试解析点分隔格式 "2025.2.3"
    final dotPattern = RegExp(r'(\d{4})\.(\d{1,2})\.(\d{1,2})');
    final dotMatch = dotPattern.firstMatch(trimmed);
    if (dotMatch != null) {
      final year = int.parse(dotMatch.group(1)!);
      final month = int.parse(dotMatch.group(2)!);
      final day = int.parse(dotMatch.group(3)!);
      return DateTime(year, month, day);
    }
    
    // 尝试解析短横线格式 "2026-01-01"
    final dashPattern = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
    final dashMatch = dashPattern.firstMatch(trimmed);
    if (dashMatch != null) {
      final year = int.parse(dashMatch.group(1)!);
      final month = int.parse(dashMatch.group(2)!);
      final day = int.parse(dashMatch.group(3)!);
      return DateTime(year, month, day);
    }
    
    // 尝试解析斜杠格式 "2026/01/01"
    final slashPattern = RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})');
    final slashMatch = slashPattern.firstMatch(trimmed);
    if (slashMatch != null) {
      final year = int.parse(slashMatch.group(1)!);
      final month = int.parse(slashMatch.group(2)!);
      final day = int.parse(slashMatch.group(3)!);
      return DateTime(year, month, day);
    }
    
    // 尝试标准 DateTime 解析
    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  /// 通用日期解析函数
  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue is DateTime) return dateValue;
    if (dateValue == null) return DateTime.now();
    
    final dateString = dateValue.toString().trim();
    
    // 尝试多种日期格式
    final formats = [
      'yyyy-MM-dd',
      'yyyy-MM-ddTHH:mm:ss.SZ',
      'yyyy-MM-ddTHH:mm:ss.SSSSSS+HH:mm',
      'yyyy-MM-ddTHH:mm:ss+HH:mm',
      'yyyy-MM-ddTHH:mm:ss.SSSSSS+00:00',
      'yyyy-MM-ddTHH:mm:ss+00:00',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy/MM/dd',
      'yyyy.MM.dd',
      'yyyy 年 M 月 d 日',
    ];
    
    for (final format in formats) {
      try {
        return DateFormat(format).parse(dateString);
      } catch (_) {
        continue;
      }
    }
    
    // 如果所有格式都失败，尝试直接解析
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return DateTime.now();
    }
  }
}

/// 智能日期解析工具类
class DateParser {
  /// 解析购买日期，支持多种格式
  /// 支持格式：
  /// - "2026 年 4 月 5 日"
  /// - "2025.2.3"
  /// - "2026-01-01"
  /// - "2026/01/01"
  /// - "2026-01-01 12:30:00"
  static DateTime? parsePurchaseDate(String input) {
    if (input.isEmpty) return null;
    
    final trimmed = input.trim();
    
    // 尝试解析中文格式 "2026 年 4 月 5 日"
    final chinesePattern = RegExp(r'(\d{4}) 年 (\d{1,2}) 月 (\d{1,2}) 日');
    final chineseMatch = chinesePattern.firstMatch(trimmed);
    if (chineseMatch != null) {
      final year = int.parse(chineseMatch.group(1)!);
      final month = int.parse(chineseMatch.group(2)!);
      final day = int.parse(chineseMatch.group(3)!);
      return DateTime(year, month, day);
    }
    
    // 尝试解析点分隔格式 "2025.2.3"
    final dotPattern = RegExp(r'(\d{4})\.(\d{1,2})\.(\d{1,2})');
    final dotMatch = dotPattern.firstMatch(trimmed);
    if (dotMatch != null) {
      final year = int.parse(dotMatch.group(1)!);
      final month = int.parse(dotMatch.group(2)!);
      final day = int.parse(dotMatch.group(3)!);
      return DateTime(year, month, day);
    }
    
    // 尝试解析短横线格式 "2026-01-01"
    final dashPattern = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
    final dashMatch = dashPattern.firstMatch(trimmed);
    if (dashMatch != null) {
      final year = int.parse(dashMatch.group(1)!);
      final month = int.parse(dashMatch.group(2)!);
      final day = int.parse(dashMatch.group(3)!);
      return DateTime(year, month, day);
    }
    
    // 尝试解析斜杠格式 "2026/01/01"
    final slashPattern = RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})');
    final slashMatch = slashPattern.firstMatch(trimmed);
    if (slashMatch != null) {
      final year = int.parse(slashMatch.group(1)!);
      final month = int.parse(slashMatch.group(2)!);
      final day = int.parse(slashMatch.group(3)!);
      return DateTime(year, month, day);
    }
    
    // 尝试标准 DateTime 解析
    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
  }
  
  /// 解析预计使用时长，支持自然语言
  /// 支持格式：
  /// - 纯数字：默认为天数
  /// - "1 年 6 个月"
  /// - "3 年"
  /// - "6 个月"
  /// - "100 天"
  /// - "1 年 6 个月 10 天"
  static int? parseLifespan(String input) {
    if (input.isEmpty) return null;
    
    final trimmed = input.trim();
    
    // 尝试纯数字（天数）
    final pureNumberPattern = RegExp(r'^(\d+)$');
    final pureMatch = pureNumberPattern.firstMatch(trimmed);
    if (pureMatch != null) {
      return int.parse(pureMatch.group(1)!);
    }
    
    // 尝试解析自然语言格式
    final yearPattern = RegExp(r'(\d+) 年');
    final monthPattern = RegExp(r'(\d+) 个？月');
    final dayPattern = RegExp(r'(\d+) 天');
    
    final yearMatch = yearPattern.firstMatch(trimmed);
    final monthMatch = monthPattern.firstMatch(trimmed);
    final dayMatch = dayPattern.firstMatch(trimmed);
    
    int totalDays = 0;
    
    if (yearMatch != null) {
      totalDays += int.parse(yearMatch.group(1)!) * 365;
    }
    
    if (monthMatch != null) {
      totalDays += int.parse(monthMatch.group(1)!) * 30;
    }
    
    if (dayMatch != null) {
      totalDays += int.parse(dayMatch.group(1)!);
    }
    
    // 如果没有匹配到任何有效格式，返回 null
    if (totalDays == 0 && yearMatch == null && monthMatch == null && dayMatch == null) {
      // 尝试作为纯数字解析
      final numberOnly = int.tryParse(trimmed);
      return numberOnly;
    }
    
    return totalDays;
  }
  
  /// 格式化日期显示
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    return DateFormat(format).format(date);
  }
  
  /// 格式化天数显示
  static String formatDays(int days, {String style = 'combined'}) {
    if (style == 'days') {
      return '$days 天';
    }
    
    // 组合格式：年/月/日
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
}
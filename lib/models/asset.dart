import 'dart:convert';
import 'package:intl/intl.dart';

/// 资产模型 V2.0 - 用于记录个人资产折旧与价值平摊
///
/// ## 字段说明
/// - id: UUID 主键
/// - assetName: 资产名称
/// - purchasePrice: 购入价格 (可为空)
/// - purchaseDate: 购买日期时间戳
/// - isPinned: 是否置顶 (0 或 1)
/// - category: 资产分类
/// - tags: 自定义标签
/// - createdAt: 创建时间时间戳
///
/// ## 状态与改动核心字段
/// - status: 状态 (0 服役中，1 已退役，2 已卖出)
/// - expectedLifespanDays: 预计寿命天数 (可为空)
/// - expireDate: 到期日时间戳 (可为空)
/// - soldPrice: 卖出价 (可为空)
/// - soldDate: 卖出/退役冻结日时间戳 (可为空)
///
/// ## 其他字段
/// - avatarPath: 头像本地路径
/// - excludeFromTotal: 不计入总资产 (0 或 1，默认 0)
/// - excludeFromDaily: 不计入日均 (0 或 1，默认 0)
class Asset {
  /// UUID 主键
  String id;

  /// 资产名称
  String assetName;

  /// 购入价格
  double? purchasePrice;

  /// 购买日期时间戳
  int purchaseDate;

  /// 是否置顶 (0 或 1)
  int isPinned;

  /// 资产分类
  String category;

  /// 自定义标签
  List<String> tags;

  /// 创建时间时间戳
  int createdAt;

  /// 状态：0 服役中，1 已退役，2 已卖出
  int status;

  /// 预计寿命天数 (可为空)
  int? expectedLifespanDays;

  /// 到期日时间戳 (可为空)
  int? expireDate;

  /// 卖出价 (可为空)
  double? soldPrice;

  /// 卖出/退役冻结日时间戳 (可为空)
  int? soldDate;

  /// 头像本地路径
  String? avatarPath;

  /// 不计入总资产 (0 或 1，默认 0)
  int excludeFromTotal;

  /// 不计入日均 (0 或 1，默认 0)
  int excludeFromDaily;

  Asset({
    required this.id,
    required this.assetName,
    this.purchasePrice,
    required this.purchaseDate,
    this.isPinned = 0,
    this.category = 'physical',
    this.tags = const [],
    required this.createdAt,
    this.status = 0,
    this.expectedLifespanDays,
    this.expireDate,
    this.soldPrice,
    this.soldDate,
    this.avatarPath,
    this.excludeFromTotal = 0,
    this.excludeFromDaily = 0,
  });

  /// 创建 Asset 的便捷工厂方法
  factory Asset.create({
    String? id,
    required String assetName,
    double? purchasePrice,
    required int purchaseDate,
    int isPinned = 0,
    String category = 'physical',
    List<String>? tags,
    int? createdAt,
    int status = 0,
    int? expectedLifespanDays,
    int? expireDate,
    double? soldPrice,
    int? soldDate,
    String? avatarPath,
    int excludeFromTotal = 0,
    int excludeFromDaily = 0,
  }) {
    return Asset(
      id: id ?? '',
      assetName: assetName,
      purchasePrice: purchasePrice,
      purchaseDate: purchaseDate,
      isPinned: isPinned,
      category: category,
      tags: tags ?? const [],
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch,
      status: status,
      expectedLifespanDays: expectedLifespanDays,
      expireDate: expireDate,
      soldPrice: soldPrice,
      soldDate: soldDate,
      avatarPath: avatarPath,
      excludeFromTotal: excludeFromTotal,
      excludeFromDaily: excludeFromDaily,
    );
  }

  /// 是否已卖出或退役
  bool get isSoldOrRetired => status == 1 || status == 2;

  /// 是否服役中
  bool get isActive => status == 0;

  /// 计算实际/冻结天数
  /// - 状态 1(退役) 或 2(卖出) 时，时间永久冻结在 soldDate
  /// - 状态 0(服役中) 时，时间持续流逝到今天
  int get calculatedDays {
    final start = DateTime.fromMillisecondsSinceEpoch(purchaseDate);
    DateTime end;

    // 状态 1(退役) 或 2(卖出) 时，时间永久冻结在 soldDate
    if ((status == 1 || status == 2) && soldDate != null) {
      end = DateTime.fromMillisecondsSinceEpoch(soldDate!);
    } else {
      // 状态 0(服役中)，时间持续流逝到今天
      end = DateTime.now();
    }

    final days = end.difference(start).inDays;
    return days > 0 ? days : 1; // 兜底：最小使用天数为 1，防止除以 0
  }

  /// 计算日均价格（核心业务逻辑）
  /// - 如果已卖出且有回血价，成本 = 买入价 - 卖出价
  /// - 服役中且未超期：按预期寿命计算固定日均
  /// - 其他情况：按实际/冻结天数计算
  double get dailyCost {
    // 基础成本：如果已卖出且有回血价，则成本 = 买入价 - 卖出价
    double cost = purchasePrice ?? 0;
    if (status == 2 && soldPrice != null) {
      cost = (purchasePrice ?? 0) - soldPrice!;
    }

    final daysUsed = calculatedDays;

    // 核心逻辑：如果是服役中 (status == 0)，且设定了预计使用天数
    if (status == 0 &&
        expectedLifespanDays != null &&
        expectedLifespanDays! > 0) {
      if (daysUsed < expectedLifespanDays!) {
        // 未超出预期寿命：按预期寿命计算固定日均
        return cost / expectedLifespanDays!;
      }
    }

    // 其他情况：已退役、已卖出、未设预期寿命、或服役已超期，均按实际/冻结天数计算
    return cost / daysUsed;
  }

  /// 计算剩余天数
  int? get remainingDays {
    final lifespan = expectedLifespanDays;
    if (lifespan == null) return null;
    final endDate = purchaseDate + Duration(days: lifespan).inMilliseconds;
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = (endDate - now) ~/ Duration.millisecondsPerDay;
    return difference > 0 ? difference : 0;
  }

  /// 计算已使用天数
  int get usedDays {
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = (now - purchaseDate) ~/ Duration.millisecondsPerDay;
    return difference > 0 ? difference : 0;
  }

  /// 计算实际使用天数（如果已卖出/退役，则计算到卖出/退役日期）
  int get actualUsedDays {
    if (soldDate != null) {
      final difference =
          (soldDate! - purchaseDate) ~/ Duration.millisecondsPerDay;
      return difference > 0 ? difference : 0;
    }
    return usedDays;
  }

  /// 是否已过期
  bool get isExpired {
    final remaining = remainingDays;
    return remaining == null || remaining == 0;
  }

  /// 计算实际日均花费（考虑卖出）
  double? get actualDailyCost {
    final price = purchasePrice;
    final sold = soldPrice;
    final date = soldDate;
    if (price == null || sold == null || date == null) return null;
    final days = (date - purchaseDate) ~/ Duration.millisecondsPerDay;
    if (days <= 0) return null;
    return (price - sold) / days;
  }

  // ==================== SQLite 映射方法 ====================

  /// 转换为 Map（用于 SQLite 插入/更新）
  /// 驼峰命名 (Dart) -> 下划线命名 (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_name': assetName,
      'purchase_price': purchasePrice,
      'purchase_date': purchaseDate,
      'is_pinned': isPinned,
      'category': category,
      'tags': jsonEncode(tags),
      'created_at': createdAt,
      'status': status,
      'expected_lifespan_days': expectedLifespanDays,
      'expire_date': expireDate,
      'sold_price': soldPrice,
      'sold_date': soldDate,
      'avatar_path': avatarPath,
      'exclude_from_total': excludeFromTotal,
      'exclude_from_daily': excludeFromDaily,
    };
  }

  /// 从 Map 创建 Asset 对象（用于 SQLite 查询结果）
  /// 下划线命名 (SQLite) -> 驼峰命名 (Dart)
  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as String,
      assetName: map['asset_name'] as String,
      purchasePrice: map['purchase_price'] != null
          ? (map['purchase_price'] as num).toDouble()
          : null,
      purchaseDate: map['purchase_date'] as int,
      isPinned: (map['is_pinned'] as int?) ?? 0,
      category: map['category'] as String? ?? 'physical',
      tags: _decodeTags(map['tags']),
      createdAt: map['created_at'] as int,
      status: (map['status'] as int?) ?? 0,
      expectedLifespanDays: map['expected_lifespan_days'] as int?,
      expireDate: map['expire_date'] as int?,
      soldPrice: map['sold_price'] != null
          ? (map['sold_price'] as num).toDouble()
          : null,
      soldDate: map['sold_date'] as int?,
      avatarPath: map['avatar_path'] as String?,
      excludeFromTotal: (map['exclude_from_total'] as int?) ?? 0,
      excludeFromDaily: (map['exclude_from_daily'] as int?) ?? 0,
    );
  }

  /// 解码标签
  static List<String> _decodeTags(dynamic tagsValue) {
    if (tagsValue == null) return [];
    if (tagsValue is List) return tagsValue.map((e) => e.toString()).toList();
    if (tagsValue is String) {
      try {
        final decoded = jsonDecode(tagsValue);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  /// 复制并修改
  Asset copyWith({
    String? id,
    String? assetName,
    double? purchasePrice,
    int? purchaseDate,
    int? isPinned,
    String? category,
    List<String>? tags,
    int? createdAt,
    int? status,
    int? expectedLifespanDays,
    int? expireDate,
    double? soldPrice,
    int? soldDate,
    String? avatarPath,
    int? excludeFromTotal,
    int? excludeFromDaily,
  }) {
    return Asset(
      id: id ?? this.id,
      assetName: assetName ?? this.assetName,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      expectedLifespanDays: expectedLifespanDays ?? this.expectedLifespanDays,
      expireDate: expireDate ?? this.expireDate,
      soldPrice: soldPrice ?? this.soldPrice,
      soldDate: soldDate ?? this.soldDate,
      avatarPath: avatarPath ?? this.avatarPath,
      excludeFromTotal: excludeFromTotal ?? this.excludeFromTotal,
      excludeFromDaily: excludeFromDaily ?? this.excludeFromDaily,
    );
  }

  @override
  String toString() {
    return 'Asset(id: $id, assetName: $assetName, purchasePrice: $purchasePrice, purchaseDate: $purchaseDate, isPinned: $isPinned, category: $category, tags: $tags, createdAt: $createdAt, status: $status, expectedLifespanDays: $expectedLifespanDays, expireDate: $expireDate, soldPrice: $soldPrice, soldDate: $soldDate, avatarPath: $avatarPath, excludeFromTotal: $excludeFromTotal, excludeFromDaily: $excludeFromDaily)';
  }

  /// 解析预计使用天数，支持自然语言
  /// 支持格式：
  /// - 纯数字：默认为天数
  /// - "5 年" 或 "5 年"
  /// - "1 年 6 个月" 或 "1 年 6 个月"
  /// - "6 个月" 或 "6 个月"
  /// - "100 天" 或 "100 天"
  /// - "1 年 6 个月 10 天" 或 "1 年 6 个月 10 天"
  static int parseExpectedDays(String input) {
    if (input.isEmpty) return 0;

    final trimmed = input.trim();

    // 尝试纯数字（天数）
    final pureNumberPattern = RegExp(r'^\s*(\d+)\s*$');
    final pureMatch = pureNumberPattern.firstMatch(trimmed);
    if (pureMatch != null) {
      return int.parse(pureMatch.group(1)!);
    }

    // 使用正则表达式精确提取数字，支持空格可选
    final yearPattern = RegExp(r'(\d+)\s*年');
    final monthPattern = RegExp(r'(\d+)\s*(?:个\s*)?月');
    final dayPattern = RegExp(r'(\d+)\s*天');

    final yearMatch = yearPattern.firstMatch(trimmed);
    final monthMatch = monthPattern.firstMatch(trimmed);
    final dayMatch = dayPattern.firstMatch(trimmed);

    int totalDays = 0;
    bool hasMatch = false;

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

    if (!hasMatch) {
      return 0;
    }

    return totalDays;
  }

  /// 解析自定义日期格式，支持手写输入
  /// 支持格式：
  /// - "2026 年 2 月 2 日" 或 "2026 年 4 月 5 日"
  /// - "2025.2.3"
  /// - "2026-01-01"
  /// - "2026/01/01"
  /// - "2026-01-01 12:30:00"
  static DateTime? parseCustomDate(String input) {
    if (input.isEmpty) return null;

    final trimmed = input.trim();
    String normalized = trimmed;

    // 检查是否包含中文日期字符
    if (normalized.contains('年') ||
        normalized.contains('月') ||
        normalized.contains('日')) {
      normalized = normalized.replaceAll(RegExp(r'\s+'), '');
      normalized = normalized.replaceAll('年', '-');
      normalized = normalized.replaceAll('月', '-');
      normalized = normalized.replaceAll('日', '');
      normalized = normalized.replaceAll(RegExp(r'-+$'), '');
    }

    // 尝试解析短横线格式
    final dashPattern = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
    final dashMatch = dashPattern.firstMatch(normalized);
    if (dashMatch != null) {
      final year = int.parse(dashMatch.group(1)!);
      final month = int.parse(dashMatch.group(2)!);
      final day = int.parse(dashMatch.group(3)!);
      try {
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }

    // 尝试解析点分隔格式
    final dotPattern = RegExp(r'^(\d{4})\.(\d{1,2})\.(\d{1,2})$');
    final dotMatch = dotPattern.firstMatch(trimmed);
    if (dotMatch != null) {
      final year = int.parse(dotMatch.group(1)!);
      final month = int.parse(dotMatch.group(2)!);
      final day = int.parse(dotMatch.group(3)!);
      try {
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }

    // 尝试解析斜杠格式
    final slashPattern = RegExp(r'^(\d{4})/(\d{1,2})/(\d{1,2})$');
    final slashMatch = slashPattern.firstMatch(trimmed);
    if (slashMatch != null) {
      final year = int.parse(slashMatch.group(1)!);
      final month = int.parse(slashMatch.group(2)!);
      final day = int.parse(slashMatch.group(3)!);
      try {
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }

    // 尝试标准 DateTime 解析
    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
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

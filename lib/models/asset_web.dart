/// ==================== Web 平台兼容的 Asset 模型 ====================
/// 由于 Isar 在 Web 平台有 64 位整数兼容性问题，
/// 此文件提供 Web 平台的基础 Asset 实现（无数据库功能）
import 'dart:convert';
import 'package:intl/intl.dart';

/// Web 平台的 Asset 模型（无 Isar 依赖）
class Asset {
  /// 本地自增主键
  int isarId;

  /// UUID 主键
  String? id;

  /// 用户 ID
  String? userId;

  /// 资产名称
  String assetName;

  /// 购入价格
  double purchasePrice;

  /// 预计使用天数
  int expectedLifespanDays;

  /// 购买日期
  DateTime purchaseDate;

  /// 是否置顶
  bool isPinned;

  /// 是否已出售
  bool isSold;

  /// 出售价格
  double? soldPrice;

  /// 出售日期
  DateTime? soldDate;

  /// 资产分类
  String category;

  /// 过期日期
  DateTime? expireDate;

  /// 续费历史记录（JSON 字符串）
  String renewalHistoryJson;

  /// 自定义标签
  List<String> tags;

  /// 创建时间
  DateTime createdAt;

  Asset({
    this.isarId = 0,
    this.id,
    this.userId,
    required this.assetName,
    required this.purchasePrice,
    required this.expectedLifespanDays,
    required this.purchaseDate,
    this.isPinned = false,
    this.isSold = false,
    this.soldPrice,
    this.soldDate,
    this.category = 'physical',
    this.expireDate,
    List<dynamic>? renewalHistory,
    this.tags = const [],
    required this.createdAt,
  }) : renewalHistoryJson = _encodeRenewalHistory(renewalHistory ?? []);

  /// 创建 Asset 的便捷工厂方法
  factory Asset.create({
    int? isarId,
    String? id,
    String? userId,
    required String assetName,
    required double purchasePrice,
    required int expectedLifespanDays,
    required DateTime purchaseDate,
    bool isPinned = false,
    bool isSold = false,
    double? soldPrice,
    DateTime? soldDate,
    String category = 'physical',
    DateTime? expireDate,
    List<dynamic>? renewalHistory,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return Asset(
      isarId: isarId ?? 0,
      id: id,
      userId: userId,
      assetName: assetName,
      purchasePrice: purchasePrice,
      expectedLifespanDays: expectedLifespanDays,
      purchaseDate: purchaseDate,
      isPinned: isPinned,
      isSold: isSold,
      soldPrice: soldPrice,
      soldDate: soldDate,
      category: category,
      expireDate: expireDate,
      renewalHistory: renewalHistory,
      tags: tags ?? const [],
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// 解码续费历史记录
  List<dynamic> get renewalHistory => _decodeRenewalHistory(renewalHistoryJson);

  /// 设置续费历史记录
  set renewalHistory(List<dynamic> value) {
    renewalHistoryJson = _encodeRenewalHistory(value);
  }

  /// 编码续费历史记录
  static String _encodeRenewalHistory(List<dynamic> history) {
    if (history.isEmpty) return '[]';
    try {
      return jsonEncode(history);
    } catch (_) {
      return '[]';
    }
  }

  /// 解码续费历史记录
  static List<dynamic> _decodeRenewalHistory(String json) {
    if (json.isEmpty || json == '[]') return [];
    try {
      return jsonDecode(json) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

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

  /// 计算实际使用天数
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

  /// 是否已过期
  bool get isExpired => remainingDays == 0;

  /// 计算实际日均花费
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

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'asset_name': assetName,
      'purchase_price': purchasePrice,
      'expected_lifespan_days': expectedLifespanDays,
      'purchase_date': purchaseDate.toIso8601String(),
      'is_pinned': isPinned,
      'is_sold': isSold,
      if (soldPrice != null) 'sold_price': soldPrice,
      if (soldDate != null) 'sold_date': soldDate!.toIso8601String(),
      'category': category,
      if (expireDate != null) 'expire_date': expireDate!.toIso8601String(),
      'renewal_history': renewalHistory,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 从 JSON 创建
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      assetName: json['asset_name'] as String,
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      expectedLifespanDays: json['expected_lifespan_days'] as int,
      purchaseDate: _parseDate(json['purchase_date']),
      isPinned: (json['is_pinned'] as bool?) ?? false,
      isSold: (json['is_sold'] as bool?) ?? false,
      soldPrice: json['sold_price'] != null ? (json['sold_price'] as num).toDouble() : null,
      soldDate: json['sold_date'] != null ? _parseDate(json['sold_date']) : null,
      category: (json['category'] as String?) ?? 'physical',
      expireDate: json['expire_date'] != null ? _parseDate(json['expire_date']) : null,
      renewalHistory: json['renewal_history'] as List<dynamic>? ?? [],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 复制并修改
  Asset copyWith({
    int? isarId,
    String? id,
    String? userId,
    String? assetName,
    double? purchasePrice,
    int? expectedLifespanDays,
    DateTime? purchaseDate,
    bool? isPinned,
    bool? isSold,
    double? soldPrice,
    DateTime? soldDate,
    String? category,
    DateTime? expireDate,
    List<dynamic>? renewalHistory,
    List<String>? tags,
  }) {
    return Asset(
      isarId: isarId ?? this.isarId,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assetName: assetName ?? this.assetName,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      expectedLifespanDays: expectedLifespanDays ?? this.expectedLifespanDays,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isPinned: isPinned ?? this.isPinned,
      isSold: isSold ?? this.isSold,
      soldPrice: soldPrice ?? this.soldPrice,
      soldDate: soldDate ?? this.soldDate,
      category: category ?? this.category,
      expireDate: expireDate ?? this.expireDate,
      renewalHistory: renewalHistory ?? this.renewalHistory,
      tags: tags ?? this.tags,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'Asset(isarId: $isarId, id: $id, assetName: $assetName, purchasePrice: $purchasePrice)';
  }

  /// 解析日期
  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue is DateTime) return dateValue;
    if (dateValue == null) return DateTime.now();
    try {
      return DateTime.parse(dateValue.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  /// 解析预计使用天数
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

    int totalDays = 0;
    bool hasMatch = false;

    final yearMatch = yearPattern.firstMatch(trimmed);
    if (yearMatch != null) {
      totalDays += int.parse(yearMatch.group(1)!) * 365;
      hasMatch = true;
    }

    final monthMatch = monthPattern.firstMatch(trimmed);
    if (monthMatch != null) {
      totalDays += int.parse(monthMatch.group(1)!) * 30;
      hasMatch = true;
    }

    final dayMatch = dayPattern.firstMatch(trimmed);
    if (dayMatch != null) {
      totalDays += int.parse(dayMatch.group(1)!);
      hasMatch = true;
    }

    return hasMatch ? totalDays : 0;
  }

  /// 解析自定义日期
  static DateTime? parseCustomDate(String input) {
    if (input.isEmpty) return null;
    final trimmed = input.trim();

    String normalized = trimmed;
    if (normalized.contains('年') || normalized.contains('月') || normalized.contains('日')) {
      normalized = normalized.replaceAll(RegExp(r'\s+'), '');
      normalized = normalized.replaceAll('年', '-');
      normalized = normalized.replaceAll('月', '-');
      normalized = normalized.replaceAll('日', '');
      normalized = normalized.replaceAll(RegExp(r'-+$'), '');
    }

    final dashPattern = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
    final dashMatch = dashPattern.firstMatch(normalized);
    if (dashMatch != null) {
      try {
        return DateTime(
          int.parse(dashMatch.group(1)!),
          int.parse(dashMatch.group(2)!),
          int.parse(dashMatch.group(3)!),
        );
      } catch (_) {
        return null;
      }
    }

    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
  }
}

/// 智能日期解析工具类
class DateParser {
  static DateTime? parsePurchaseDate(String input) {
    return Asset.parseCustomDate(input);
  }

  static int? parseLifespan(String input) {
    if (input.isEmpty) return null;
    final result = Asset.parseExpectedDays(input);
    return result > 0 ? result : null;
  }

  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    return DateFormat(format).format(date);
  }

  static String formatDays(int days, {String style = 'combined'}) {
    if (style == 'days') return '$days 天';

    final years = days ~/ 365;
    final remainingAfterYears = days % 365;
    final months = remainingAfterYears ~/ 30;
    final remainingDays = remainingAfterYears % 30;

    final parts = <String>[];
    if (years > 0) parts.add('$years 年');
    if (months > 0) parts.add('$months 月');
    if (remainingDays > 0) parts.add('$remainingDays 天');

    return parts.isEmpty ? '0 天' : parts.join('');
  }
}

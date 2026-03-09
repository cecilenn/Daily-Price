import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

part 'asset.g.dart';

/// 资产模型 - 用于记录个人资产折旧与价值平摊
/// 数据库字段对应：
/// - isarId: Isar 本地自增主键（64位整数）
/// - id: UUID（用于与远端服务器映射同步）
/// - user_id: 用户 ID（关联 auth.users）
/// - asset_name: 资产名称
/// - purchase_price: 购入价格
/// - expected_lifespan_days: 预计使用天数
/// - purchase_date: 购买日期
/// - is_pinned: 是否置顶
/// - is_sold: 是否已出售
/// - sold_price: 出售价格
/// - sold_date: 出售日期
/// - category: 资产分类 (physical, virtual, subscription)
/// - expire_date: 过期日期（用于订阅类资产）
/// - renewal_history: 续费历史记录
/// - tags: 自定义标签
/// - created_at: 创建时间
@collection
class Asset {
  /// Isar 本地自增主键（64位整数）
  Id isarId = Isar.autoIncrement;

  /// UUID 主键（用于与远端服务器如 PocketBase 进行映射同步）
  @Index()
  String? id;

  /// 用户 ID，用于多用户数据隔离
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

  /// 资产分类：physical(实体), virtual(虚拟), subscription(订阅)
  String category;

  /// 过期日期（主要用于订阅类资产）
  DateTime? expireDate;

  /// 续费历史记录（JSON 字符串存储）
  String renewalHistoryJson;

  /// 自定义标签
  List<String> tags;

  /// 创建时间
  DateTime createdAt;

  Asset({
    this.isarId = Isar.autoIncrement,
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

  /// 创建 Asset 的便捷工厂方法（自动设置创建时间）
  factory Asset.create({
    Id? isarId,
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
      isarId: isarId ?? Isar.autoIncrement,
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
  /// 使用 @ignore 注解告诉 Isar 忽略此 getter/setter
  @ignore
  List<dynamic> get renewalHistory => _decodeRenewalHistory(renewalHistoryJson);

  /// 设置续费历史记录
  @ignore
  set renewalHistory(List<dynamic> value) {
    renewalHistoryJson = _encodeRenewalHistory(value);
  }

  /// 编码续费历史记录为 JSON 字符串
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

  /// 从 JSON 创建 Asset 对象（用于数据库查询结果）
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
    Id? isarId,
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
    return 'Asset(isarId: $isarId, id: $id, assetName: $assetName, purchasePrice: $purchasePrice, expectedLifespanDays: $expectedLifespanDays, purchaseDate: $purchaseDate, isPinned: $isPinned, isSold: $isSold, soldPrice: $soldPrice, soldDate: $soldDate, category: $category, expireDate: $expireDate, renewalHistory: $renewalHistory, tags: $tags)';
  }

  /// 解析预计使用天数，支持自然语言
  /// 支持格式：
  /// - 纯数字：默认为天数
  /// - "5年" 或 "5 年"
  /// - "1年6个月" 或 "1 年 6 个月"
  /// - "6个月" 或 "6 个月"
  /// - "100天" 或 "100 天"
  /// - "1年6个月10天" 或 "1 年 6 个月 10 天"
  static int parseExpectedDays(String input) {
    if (input.isEmpty) return 0;
    
    final trimmed = input.trim();
    
    // 尝试纯数字（天数）- 允许前后有空白
    final pureNumberPattern = RegExp(r'^\s*(\d+)\s*$');
    final pureMatch = pureNumberPattern.firstMatch(trimmed);
    if (pureMatch != null) {
      return int.parse(pureMatch.group(1)!);
    }
    
    // 使用正则表达式精确提取数字，支持空格可选
    // 年：匹配 "数字 + 可选空格 + 年"
    final yearPattern = RegExp(r'(\d+)\s*年');
    // 月：匹配 "数字 + 可选空格 + 个 + 可选空格 + 月" 或 "数字 + 可选空格 + 月"
    final monthPattern = RegExp(r'(\d+)\s*(?:个\s*)?月');
    // 天：匹配 "数字 + 可选空格 + 天"
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
    
    // 如果没有匹配到任何有效格式，返回 0
    if (!hasMatch) {
      return 0;
    }
    
    return totalDays;
  }

  /// 解析自定义日期格式，支持手写输入
  /// 支持格式：
  /// - "2026年2月2日" 或 "2026 年 4 月 5 日"
  /// - "2025.2.3"
  /// - "2026-01-01"
  /// - "2026/01/01"
  /// - "2026-01-01 12:30:00"
  static DateTime? parseCustomDate(String input) {
    if (input.isEmpty) return null;
    
    final trimmed = input.trim();
    
    // 预处理：将中文日期格式转换为标准格式
    // 例如："2026年2月2日" -> "2026-2-2"
    String normalized = trimmed;
    
    // 检查是否包含中文日期字符
    if (normalized.contains('年') || normalized.contains('月') || normalized.contains('日')) {
      // 移除所有空白字符
      normalized = normalized.replaceAll(RegExp(r'\s+'), '');
      // 将 '年' 和 '月' 替换为 '-'
      normalized = normalized.replaceAll('年', '-');
      normalized = normalized.replaceAll('月', '-');
      // 将 '日' 去除
      normalized = normalized.replaceAll('日', '');
      // 移除末尾可能的多余 '-'
      normalized = normalized.replaceAll(RegExp(r'-+$'), '');
    }
    
    // 尝试解析短横线格式 "2026-2-2" 或 "2026-01-01"
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
    
    // 尝试解析点分隔格式 "2025.2.3"
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
    
    // 尝试解析斜杠格式 "2026/01/01"
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
  /// - "2026年2月2日" 或 "2026 年 4 月 5 日"
  /// - "2025.2.3"
  /// - "2026-01-01"
  /// - "2026/01/01"
  /// - "2026-01-01 12:30:00"
  static DateTime? parsePurchaseDate(String input) {
    // 直接调用 Asset.parseCustomDate，保持逻辑一致
    return Asset.parseCustomDate(input);
  }
  
  /// 解析预计使用时长，支持自然语言
  /// 支持格式：
  /// - 纯数字：默认为天数
  /// - "5年" 或 "5 年"
  /// - "1年6个月" 或 "1 年 6 个月"
  /// - "6个月" 或 "6 个月"
  /// - "100天" 或 "100 天"
  /// - "1年6个月10天" 或 "1 年 6 个月 10 天"
  static int? parseLifespan(String input) {
    if (input.isEmpty) return null;
    
    final trimmed = input.trim();
    
    // 尝试纯数字（天数）- 允许前后有空白
    final pureNumberPattern = RegExp(r'^\s*(\d+)\s*$');
    final pureMatch = pureNumberPattern.firstMatch(trimmed);
    if (pureMatch != null) {
      return int.parse(pureMatch.group(1)!);
    }
    
    // 使用正则表达式精确提取数字，支持空格可选
    // 年：匹配 "数字 + 可选空格 + 年"
    final yearPattern = RegExp(r'(\d+)\s*年');
    // 月：匹配 "数字 + 可选空格 + 个 + 可选空格 + 月" 或 "数字 + 可选空格 + 月"
    final monthPattern = RegExp(r'(\d+)\s*(?:个\s*)?月');
    // 天：匹配 "数字 + 可选空格 + 天"
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
    
    // 如果没有匹配到任何有效格式，返回 null
    if (!hasMatch) {
      return null;
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
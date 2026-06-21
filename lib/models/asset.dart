import 'dart:convert';
import '../utils/asset_input_parser.dart';
import 'asset_category.dart';
import 'asset_records.dart';

export 'asset_records.dart';

part 'asset_metrics.dart';

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

  /// 头像背景颜色 (16进制颜色值，默认 0xFFE0E0E0)
  int? avatarBgColor;

  /// 头像文字 (用户自定义的1-2个字符)
  String? avatarText;

  /// 头像图标 CodePoint (Material Icon 的 codePoint)
  int? avatarIconCodePoint;

  /// 不计入总资产 (0 或 1，默认 0)
  int excludeFromTotal;

  /// 不计入日均 (0 或 1，默认 0)
  int excludeFromDaily;

  /// 所有权类型：'buyout'（买断）或 'subscription'（订阅）
  final String ownershipType;

  /// 续费记录列表
  final List<RenewalRecord> renewals;

  /// 耗材定义列表
  final List<ConsumableRecord> consumables;

  /// 耗材更换记录列表
  final List<ReplacementRecord> replacements;

  Asset({
    required this.id,
    required this.assetName,
    this.purchasePrice,
    required this.purchaseDate,
    this.isPinned = 0,
    String category = AssetCategory.uncategorized,
    this.tags = const [],
    required this.createdAt,
    this.status = 0,
    this.expectedLifespanDays,
    this.expireDate,
    this.soldPrice,
    this.soldDate,
    this.avatarPath,
    this.avatarBgColor,
    this.avatarText,
    this.avatarIconCodePoint,
    this.excludeFromTotal = 0,
    this.excludeFromDaily = 0,
    String ownershipType = 'buyout',
    this.renewals = const [],
    this.consumables = const [],
    this.replacements = const [],
  }) : category = AssetCategory.normalize(category),
       ownershipType = AssetCategory.normalizeOwnership(
         ownershipType: ownershipType,
         category: category,
       );

  /// 创建 Asset 的便捷工厂方法
  factory Asset.create({
    String? id,
    required String assetName,
    double? purchasePrice,
    required int purchaseDate,
    int isPinned = 0,
    String category = AssetCategory.uncategorized,
    List<String>? tags,
    int? createdAt,
    int status = 0,
    int? expectedLifespanDays,
    int? expireDate,
    double? soldPrice,
    int? soldDate,
    String? avatarPath,
    int? avatarBgColor,
    String? avatarText,
    int? avatarIconCodePoint,
    int excludeFromTotal = 0,
    int excludeFromDaily = 0,
    String ownershipType = 'buyout',
    List<RenewalRecord>? renewals,
    List<ConsumableRecord>? consumables,
    List<ReplacementRecord>? replacements,
  }) {
    return Asset(
      id: id ?? '',
      assetName: assetName,
      purchasePrice: purchasePrice,
      purchaseDate: purchaseDate,
      isPinned: isPinned,
      category: AssetCategory.normalize(category),
      tags: tags ?? const [],
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch,
      status: status,
      expectedLifespanDays: expectedLifespanDays,
      expireDate: expireDate,
      soldPrice: soldPrice,
      soldDate: soldDate,
      avatarPath: avatarPath,
      avatarBgColor: avatarBgColor,
      avatarText: avatarText,
      avatarIconCodePoint: avatarIconCodePoint,
      excludeFromTotal: excludeFromTotal,
      excludeFromDaily: excludeFromDaily,
      ownershipType: AssetCategory.normalizeOwnership(
        ownershipType: ownershipType,
        category: category,
      ),
      renewals: renewals ?? const [],
      consumables: consumables ?? const [],
      replacements: replacements ?? const [],
    );
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
      'avatar_bg_color': avatarBgColor,
      'avatar_text': avatarText,
      'avatar_icon_code_point': avatarIconCodePoint,
      'exclude_from_total': excludeFromTotal,
      'exclude_from_daily': excludeFromDaily,
      'ownership_type': ownershipType,
      'renewals': jsonEncode(renewals.map((r) => r.toMap()).toList()),
      'consumables': jsonEncode(consumables.map((c) => c.toMap()).toList()),
      'replacements': jsonEncode(replacements.map((r) => r.toMap()).toList()),
    };
  }

  /// 从 Map 创建 Asset 对象（用于 SQLite 查询结果）
  /// 下划线命名 (SQLite) -> 驼峰命名 (Dart)
  factory Asset.fromMap(Map<String, dynamic> map) {
    final rawCategory = map['category'] as String?;
    return Asset(
      id: map['id'] as String,
      assetName: map['asset_name'] as String,
      purchasePrice: map['purchase_price'] != null
          ? (map['purchase_price'] as num).toDouble()
          : null,
      purchaseDate: map['purchase_date'] as int,
      isPinned: (map['is_pinned'] as int?) ?? 0,
      category: AssetCategory.normalize(rawCategory),
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
      avatarBgColor: map['avatar_bg_color'] as int?,
      avatarText: map['avatar_text'] as String?,
      avatarIconCodePoint: map['avatar_icon_code_point'] as int?,
      excludeFromTotal: (map['exclude_from_total'] as int?) ?? 0,
      excludeFromDaily: (map['exclude_from_daily'] as int?) ?? 0,
      ownershipType: AssetCategory.normalizeOwnership(
        ownershipType: map['ownership_type'] as String?,
        category: rawCategory,
      ),
      renewals: _decodeRenewals(map['renewals'] as String?),
      consumables: _decodeConsumables(map['consumables'] as String?),
      replacements: _decodeReplacements(map['replacements'] as String?),
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

  /// 解码续费记录
  static List<RenewalRecord> _decodeRenewals(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => RenewalRecord.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 解码耗材定义记录
  static List<ConsumableRecord> _decodeConsumables(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => ConsumableRecord.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 解码耗材更换记录
  static List<ReplacementRecord> _decodeReplacements(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => ReplacementRecord.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
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
    int? avatarBgColor,
    String? avatarText,
    int? avatarIconCodePoint,
    int? excludeFromTotal,
    int? excludeFromDaily,
    String? ownershipType,
    List<RenewalRecord>? renewals,
    List<ConsumableRecord>? consumables,
    List<ReplacementRecord>? replacements,
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
      avatarBgColor: avatarBgColor ?? this.avatarBgColor,
      avatarText: avatarText ?? this.avatarText,
      avatarIconCodePoint: avatarIconCodePoint ?? this.avatarIconCodePoint,
      excludeFromTotal: excludeFromTotal ?? this.excludeFromTotal,
      excludeFromDaily: excludeFromDaily ?? this.excludeFromDaily,
      ownershipType: ownershipType ?? this.ownershipType,
      renewals: renewals ?? this.renewals,
      consumables: consumables ?? this.consumables,
      replacements: replacements ?? this.replacements,
    );
  }

  @override
  String toString() {
    return 'Asset(id: $id, assetName: $assetName, purchasePrice: $purchasePrice, purchaseDate: $purchaseDate, isPinned: $isPinned, category: $category, tags: $tags, createdAt: $createdAt, status: $status, expectedLifespanDays: $expectedLifespanDays, expireDate: $expireDate, soldPrice: $soldPrice, soldDate: $soldDate, avatarPath: $avatarPath, avatarBgColor: $avatarBgColor, avatarText: $avatarText, avatarIconCodePoint: $avatarIconCodePoint, excludeFromTotal: $excludeFromTotal, excludeFromDaily: $excludeFromDaily)';
  }

  /// 解析预计使用天数，支持自然语言
  /// 支持格式：
  /// - 纯数字：默认为天数
  /// - "5 年" 或 "5 年"
  /// - "1 年 6 个月" 或 "1 年 6 个月"
  /// - "6 个月" 或 "6 个月"
  /// - "100 天" 或 "100 天"
  /// - "1 年 6 个月 10 天" 或 "1 年 6 个月 10 天"
  static int parseExpectedDays(String input) =>
      AssetInputParser.parseExpectedDays(input);

  /// 解析自定义日期格式，支持手写输入
  /// 支持格式：
  /// - "2026 年 2 月 2 日" 或 "2026 年 4 月 5 日"
  /// - "2025.2.3"
  /// - "2026-01-01"
  /// - "2026/01/01"
  /// - "2026-01-01 12:30:00"
  static DateTime? parseCustomDate(String input) =>
      AssetInputParser.parseCustomDate(input);

  /// 格式化日期显示
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) =>
      AssetInputParser.formatDate(date, format: format);

  /// 格式化天数显示
  static String formatDays(int days, {String style = 'combined'}) =>
      AssetInputParser.formatDays(days, style: style);
}

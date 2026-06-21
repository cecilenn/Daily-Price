import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/asset.dart';
import '../models/asset_category.dart';

class ParsedAssetQr {
  final String? originalId;
  final Asset asset;

  const ParsedAssetQr({required this.originalId, required this.asset});
}

class AssetQrService {
  static ParsedAssetQr parse(String qrData) {
    final jsonData = jsonDecode(qrData) as Map<String, dynamic>;

    if (jsonData['assetName'] == null && jsonData['asset_name'] == null) {
      throw const FormatException('缺少资产名称字段');
    }

    final originalId = _parseString(jsonData['id']);
    return ParsedAssetQr(
      originalId: originalId,
      asset: Asset(
        id: originalId ?? const Uuid().v4(),
        assetName:
            _parseString(jsonData['assetName']) ??
            _parseString(jsonData['asset_name']) ??
            '未知资产',
        purchasePrice:
            _parseDouble(jsonData['purchasePrice']) ??
            _parseDouble(jsonData['purchase_price']),
        purchaseDate:
            _parseInt(jsonData['purchaseDate']) ??
            _parseInt(jsonData['purchase_date']) ??
            DateTime.now().millisecondsSinceEpoch,
        expectedLifespanDays:
            _parseInt(jsonData['expectedLifespanDays']) ??
            _parseInt(jsonData['expected_lifespan_days']),
        expireDate:
            _parseInt(jsonData['expireDate']) ??
            _parseInt(jsonData['expire_date']),
        status: _parseInt(jsonData['status']) ?? 0,
        category: AssetCategory.normalize(_parseString(jsonData['category'])),
        ownershipType: AssetCategory.normalizeOwnership(
          ownershipType:
              _parseString(jsonData['ownershipType']) ??
              _parseString(jsonData['ownership_type']),
          category: _parseString(jsonData['category']),
        ),
        tags: jsonData['tags'] is List
            ? (jsonData['tags'] as List).map((e) => e.toString()).toList()
            : [],
        createdAt:
            _parseInt(jsonData['createdAt']) ??
            _parseInt(jsonData['created_at']) ??
            DateTime.now().millisecondsSinceEpoch,
        isPinned: _parseFlag(jsonData['isPinned'] ?? jsonData['is_pinned']),
        excludeFromTotal: _parseFlag(
          jsonData['excludeFromTotal'] ?? jsonData['exclude_from_total'],
        ),
        excludeFromDaily: _parseFlag(
          jsonData['excludeFromDaily'] ?? jsonData['exclude_from_daily'],
        ),
        soldPrice:
            _parseDouble(jsonData['soldPrice']) ??
            _parseDouble(jsonData['sold_price']),
        soldDate:
            _parseInt(jsonData['soldDate']) ?? _parseInt(jsonData['sold_date']),
        renewals: _decodeJsonList(jsonData['renewals'], RenewalRecord.fromMap),
        consumables: _decodeJsonList(
          jsonData['consumables'],
          ConsumableRecord.fromMap,
        ),
        replacements: _decodeJsonList(
          jsonData['replacements'],
          ReplacementRecord.fromMap,
        ),
        avatarPath: null,
      ),
    );
  }

  static List<T> _decodeJsonList<T>(
    dynamic json,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    if (json == null) return [];
    try {
      if (json is List) {
        return json.map((e) => fromMap(e as Map<String, dynamic>)).toList();
      }
      if (json is String && json.isNotEmpty) {
        final list = jsonDecode(json) as List;
        return list.map((e) => fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static String? _parseString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static int _parseFlag(dynamic value) {
    if (value is bool) return value ? 1 : 0;
    final parsed = _parseInt(value);
    if (parsed != null) return parsed == 0 ? 0 : 1;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == 'yes' || text == 'y' ? 1 : 0;
  }
}

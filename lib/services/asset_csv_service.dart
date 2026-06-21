import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../models/asset.dart';
import '../models/asset_category.dart';

class AssetCsvParseResult {
  final List<Asset> assets;
  final int skippedRows;

  const AssetCsvParseResult({required this.assets, required this.skippedRows});
}

class AssetCsvService {
  static const _headers = [
    'id',
    'asset_name',
    'purchase_price',
    'expected_lifespan_days',
    'purchase_date',
    'is_pinned',
    'status',
    'sold_price',
    'sold_date',
    'category',
    'expire_date',
    'tags',
    'created_at',
    'ownership_type',
    'avatar_bg_color',
    'avatar_text',
    'avatar_icon_code_point',
    'exclude_from_total',
    'exclude_from_daily',
    'renewals',
    'consumables',
    'replacements',
  ];

  static String encode(List<Asset> assets) {
    final csvData = <List<dynamic>>[_headers];

    for (final asset in assets) {
      csvData.add([
        asset.id,
        asset.assetName,
        asset.purchasePrice ?? '',
        asset.expectedLifespanDays ?? '',
        _formatTimestamp(asset.purchaseDate),
        asset.isPinned == 1 ? 'true' : 'false',
        asset.status,
        asset.soldPrice ?? '',
        _formatTimestamp(asset.soldDate),
        asset.category,
        _formatTimestamp(asset.expireDate),
        asset.tags.join(';'),
        _formatTimestamp(asset.createdAt),
        asset.ownershipType,
        asset.avatarBgColor ?? '',
        asset.avatarText ?? '',
        asset.avatarIconCodePoint ?? '',
        asset.excludeFromTotal,
        asset.excludeFromDaily,
        jsonEncode(asset.renewals.map((r) => r.toMap()).toList()),
        jsonEncode(asset.consumables.map((c) => c.toMap()).toList()),
        jsonEncode(asset.replacements.map((r) => r.toMap()).toList()),
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  static AssetCsvParseResult parse(String csvString) {
    final normalizedCsv = csvString
        .trim()
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final csvRows = const CsvToListConverter(eol: '\n').convert(normalizedCsv);
    if (csvRows.length < 2) {
      throw const FormatException('CSV 文件为空或格式不正确');
    }

    final header = csvRows[0]
        .map((e) => e.toString().trim().toLowerCase())
        .toList();
    final fieldIndex = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      fieldIndex[header[i]] = i;
    }

    final hasAssetName =
        fieldIndex.containsKey('asset_name') ||
        fieldIndex.containsKey('name') ||
        fieldIndex.containsKey('title');
    if (!hasAssetName) {
      throw FormatException(
        'CSV 缺少必要字段：asset_name 或 name 或 title\n当前表头：$header',
      );
    }

    final assets = <Asset>[];
    var skippedRows = 0;

    for (var i = 1; i < csvRows.length; i++) {
      final row = csvRows[i];
      if (row.isEmpty) {
        skippedRows++;
        continue;
      }

      try {
        final getRowValue = _rowValueReader(fieldIndex, row);
        final assetName = getRowValue(['asset_name', 'name', 'title']);
        if (assetName == null || assetName.isEmpty) {
          skippedRows++;
          continue;
        }

        final rawCategory = getRowValue(['category', 'type']);
        final isSoldStr = getRowValue(['is_sold', 'sold']);
        final statusStr = getRowValue(['status']);
        final isSold = isSoldStr?.toLowerCase() == 'true';

        var status = 0;
        if (statusStr != null) {
          status = int.tryParse(statusStr) ?? 0;
        } else if (isSold) {
          status = 2;
        }

        assets.add(
          Asset(
            id: getRowValue(['id', 'uuid']) ?? '',
            assetName: assetName,
            purchasePrice: _parseDouble(
              getRowValue(['purchase_price', 'price']),
            ),
            expectedLifespanDays: _parseInt(
              getRowValue([
                'expected_lifespan_days',
                'lifespan_days',
                'lifespan',
              ]),
            ),
            purchaseDate:
                _parseDateString(
                  getRowValue(['purchase_date', 'buy_date', 'date']),
                )?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            isPinned: _parseBool(getRowValue(['is_pinned', 'pinned'])) ? 1 : 0,
            status: status,
            soldPrice: _parseDouble(getRowValue(['sold_price', 'sell_price'])),
            soldDate: _parseDateString(
              getRowValue(['sold_date', 'sell_date']),
            )?.millisecondsSinceEpoch,
            category: AssetCategory.normalize(rawCategory),
            expireDate: _parseDateString(
              getRowValue(['expire_date', 'expiry_date']),
            )?.millisecondsSinceEpoch,
            tags: _parseTags(getRowValue(['tags', 'tag'])),
            createdAt:
                _parseDateString(
                  getRowValue(['created_at', 'created_date', 'created']),
                )?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            ownershipType: AssetCategory.normalizeOwnership(
              ownershipType: getRowValue(['ownership_type']),
              category: rawCategory,
            ),
            avatarBgColor: _parseInt(getRowValue(['avatar_bg_color'])),
            avatarText: getRowValue(['avatar_text']),
            avatarIconCodePoint: _parseInt(
              getRowValue(['avatar_icon_code_point']),
            ),
            excludeFromTotal: _parseBool(getRowValue(['exclude_from_total']))
                ? 1
                : 0,
            excludeFromDaily: _parseBool(getRowValue(['exclude_from_daily']))
                ? 1
                : 0,
            renewals: _parseList(
              getRowValue(['renewals']),
              RenewalRecord.fromMap,
            ),
            consumables: _parseList(
              getRowValue(['consumables']),
              ConsumableRecord.fromMap,
            ),
            replacements: _parseList(
              getRowValue(['replacements']),
              ReplacementRecord.fromMap,
            ),
          ),
        );
      } catch (_) {
        skippedRows++;
      }
    }

    return AssetCsvParseResult(assets: assets, skippedRows: skippedRows);
  }

  static String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String? Function(List<String>) _rowValueReader(
    Map<String, int> fieldIndex,
    List<dynamic> row,
  ) {
    return (possibleFieldNames) {
      for (final fieldName in possibleFieldNames) {
        final idx = fieldIndex[fieldName.toLowerCase()];
        if (idx != null && idx < row.length) {
          final val = row[idx];
          return (val == null || val.toString().trim().isEmpty)
              ? null
              : val.toString().trim();
        }
      }
      return null;
    };
  }

  static DateTime? _parseDateString(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    final trimmed = dateStr.trim();
    final timestamp = int.tryParse(trimmed);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    final formats = [
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'yyyy.MM.dd',
      'yyyy 年 M 月 d 日',
      'yyyy 年 MM 月 dd 日',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(trimmed);
      } catch (_) {
        continue;
      }
    }

    return DateTime.tryParse(trimmed);
  }

  static double? _parseDouble(String? value) {
    return value == null ? null : double.tryParse(value);
  }

  static int? _parseInt(String? value) {
    return value == null ? null : int.tryParse(value);
  }

  static bool _parseBool(String? value) {
    if (value == null) return false;
    switch (value.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'y':
        return true;
      default:
        return false;
    }
  }

  static List<String> _parseTags(String? tags) {
    if (tags == null || tags.isEmpty) return [];
    return tags
        .split(';')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<T> _parseList<T>(
    String? json,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}

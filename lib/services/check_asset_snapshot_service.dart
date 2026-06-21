import 'dart:convert';

import '../models/asset.dart';
import '../models/asset_category.dart';
import 'asset_qr_service.dart';

class CheckAssetSnapshot {
  final String assetId;
  final Map<String, dynamic> data;

  const CheckAssetSnapshot({required this.assetId, required this.data});
}

class CheckAssetSnapshotService {
  const CheckAssetSnapshotService._();

  static String encode(Map<String, dynamic> data) => jsonEncode(data);

  static CheckAssetSnapshot fromScannedValue(String rawValue) {
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic>) {
        if (decoded['assetName'] != null || decoded['asset_name'] != null) {
          final parsed = AssetQrService.parse(rawValue);
          return fromAsset(parsed.asset, assetId: parsed.originalId);
        }
        return fromMap(decoded, fallbackId: rawValue);
      }
    } catch (_) {}

    return CheckAssetSnapshot(
      assetId: rawValue,
      data: {'id': rawValue, 'assetName': '未知资产'},
    );
  }

  static CheckAssetSnapshot fromAsset(Asset asset, {String? assetId}) {
    return CheckAssetSnapshot(
      assetId: assetId?.isNotEmpty == true ? assetId! : asset.id,
      data: {
        'id': asset.id,
        'assetName': asset.assetName,
        'purchasePrice': asset.purchasePrice,
        'purchaseDate': asset.purchaseDate,
        'category': asset.category,
        'status': asset.status,
        'expectedLifespanDays': asset.expectedLifespanDays,
        'tags': asset.tags,
      },
    );
  }

  static CheckAssetSnapshot fromMap(
    Map<String, dynamic> data, {
    required String fallbackId,
  }) {
    final assetId = data['id']?.toString();
    final category = AssetCategory.normalize(data['category']?.toString());
    return CheckAssetSnapshot(
      assetId: assetId?.isNotEmpty == true ? assetId! : fallbackId,
      data: {
        'id': assetId?.isNotEmpty == true ? assetId : fallbackId,
        'assetName':
            data['assetName']?.toString() ??
            data['asset_name']?.toString() ??
            '未知资产',
        'purchasePrice':
            (data['purchasePrice'] as num?)?.toDouble() ??
            (data['purchase_price'] as num?)?.toDouble(),
        'purchaseDate': data['purchaseDate'] as int? ?? data['purchase_date'],
        'category': category,
        'status': data['status'] as int?,
        'expectedLifespanDays':
            data['expectedLifespanDays'] as int? ??
            data['expected_lifespan_days'],
        'tags': data['tags'] is List
            ? (data['tags'] as List).map((e) => e.toString()).toList()
            : <String>[],
      },
    );
  }
}

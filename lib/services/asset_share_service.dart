import 'dart:convert';

import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';

import '../models/asset.dart';

class AssetShareService {
  static String serializeToQrJson(Asset asset) {
    final data = <String, dynamic>{
      'id': asset.id,
      'assetName': asset.assetName,
      'purchasePrice': asset.purchasePrice,
      'purchaseDate': asset.purchaseDate,
      'expectedLifespanDays': asset.expectedLifespanDays,
      'expireDate': asset.expireDate,
      'status': asset.status,
      'category': asset.category,
      'ownershipType': asset.ownershipType,
      'tags': asset.tags,
      'excludeFromTotal': asset.excludeFromTotal,
      'excludeFromDaily': asset.excludeFromDaily,
      'soldPrice': asset.soldPrice,
      'soldDate': asset.soldDate,
      'createdAt': asset.createdAt,
      'isPinned': asset.isPinned,
      if (asset.renewals.isNotEmpty)
        'renewals': asset.renewals.take(20).map((r) => r.toMap()).toList(),
      if (asset.hasConsumables)
        'consumables': asset.consumables
            .take(10)
            .map(
              (consumable) => {
                'name': consumable.name,
                'price': consumable.price,
                'cycle_days': consumable.cycleDays,
                'purchased_at': consumable.purchasedAt,
              },
            )
            .toList(),
      if (asset.replacements.isNotEmpty)
        'replacements': asset.replacements
            .take(20)
            .map(
              (record) => {
                'consumable_name': record.consumableName,
                'replaced_at': record.replacedAt,
                'price': record.price,
              },
            )
            .toList(),
    };
    return jsonEncode(data);
  }

  static Future<bool> saveQrToGallery(
    ScreenshotController screenshotController,
  ) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }

      final bytes = await screenshotController.capture();
      if (bytes == null) return false;

      await Gal.putImageBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }
}

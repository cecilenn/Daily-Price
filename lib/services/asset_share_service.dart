import 'dart:convert';

import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';

import '../models/asset.dart';

class AssetShareService {
  static String serializeToQrJson(Asset asset) {
    final data = <String, dynamic>{
      'id': asset.id,
      'n': asset.assetName,
      'pd': asset.purchaseDate,
      'st': asset.status,
      'cat': asset.category,
      'own': asset.ownershipType,
      'created': asset.createdAt,
    };

    void put(String key, Object? value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      if (value is List && value.isEmpty) return;
      data[key] = value;
    }

    put('p', asset.purchasePrice);
    put('life', asset.expectedLifespanDays);
    put('exp', asset.expireDate);
    put('tags', asset.tags);
    if (asset.excludeFromTotal != 0) put('xTotal', asset.excludeFromTotal);
    if (asset.excludeFromDaily != 0) put('xDaily', asset.excludeFromDaily);
    put('soldP', asset.soldPrice);
    put('soldD', asset.soldDate);
    if (asset.isPinned != 0) put('pin', asset.isPinned);
    put(
      'ren',
      asset.renewals
          .take(20)
          .map(
            (r) => {
              'id': r.id,
              'rd': r.renewalDate,
              'p': r.price,
              'dur': r.durationDays,
            },
          )
          .toList(),
    );
    put(
      'con',
      asset.consumables
          .take(10)
          .map(
            (c) => {
              'id': c.id,
              'n': c.name,
              'p': c.price,
              'cycle': c.cycleDays,
              'at': c.purchasedAt,
              'upd': c.updatedAt,
            },
          )
          .toList(),
    );
    put(
      'rep',
      asset.replacements
          .take(20)
          .map(
            (r) => {
              'id': r.id,
              'n': r.consumableName,
              'at': r.replacedAt,
              'p': r.price,
              if (r.note != null && r.note!.isNotEmpty) 'note': r.note,
            },
          )
          .toList(),
    );

    return jsonEncode({'v': 2, 't': 'asset', 'd': data});
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

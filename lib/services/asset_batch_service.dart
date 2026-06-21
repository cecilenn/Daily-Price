import '../models/asset.dart';
import '../models/asset_category.dart';
import '../providers/asset_provider.dart';
import 'asset_csv_service.dart';

class AssetBatchSharePayload {
  final String csvString;
  final String defaultFileName;
  final int assetCount;

  const AssetBatchSharePayload({
    required this.csvString,
    required this.defaultFileName,
    required this.assetCount,
  });
}

class AssetBatchService {
  static List<Asset> selectedAssets(
    List<Asset> assets,
    Iterable<String> selectedIds,
  ) {
    final ids = selectedIds.toSet();
    return assets.where((asset) => ids.contains(asset.id)).toList();
  }

  static Future<int> deleteAssets(
    AssetProvider provider,
    Iterable<String> selectedIds,
  ) async {
    var deletedCount = 0;
    for (final id in selectedIds.toList()) {
      try {
        await provider.deleteAsset(id);
        deletedCount++;
      } catch (_) {
        // Continue deleting remaining assets.
      }
    }
    return deletedCount;
  }

  static Future<int> addTag(
    AssetProvider provider,
    Iterable<String> selectedIds,
    String tag,
  ) async {
    var updatedCount = 0;
    final ids = selectedIds.toSet();
    final assets = provider.assets.where((asset) => ids.contains(asset.id));

    for (final asset in assets) {
      if (!asset.tags.contains(tag)) {
        await provider.saveAsset(asset.copyWith(tags: [...asset.tags, tag]));
        updatedCount++;
      }
    }

    return updatedCount;
  }

  static Future<int> updateCategory(
    AssetProvider provider,
    Iterable<String> selectedIds,
    String category,
  ) async {
    var updatedCount = 0;
    final normalizedCategory = AssetCategory.normalize(category);
    final ids = selectedIds.toSet();
    final assets = provider.assets.where((asset) => ids.contains(asset.id));

    for (final asset in assets) {
      if (asset.category != normalizedCategory) {
        await provider.saveAsset(asset.copyWith(category: normalizedCategory));
        updatedCount++;
      }
    }

    return updatedCount;
  }

  static AssetBatchSharePayload? prepareSharePayload(
    List<Asset> assets,
    Iterable<String> selectedIds, {
    required int timestamp,
  }) {
    final selected = selectedAssets(assets, selectedIds);
    if (selected.isEmpty) return null;

    return AssetBatchSharePayload(
      csvString: AssetCsvService.encode(selected),
      defaultFileName: 'daily_price_selected_$timestamp.csv',
      assetCount: selected.length,
    );
  }
}

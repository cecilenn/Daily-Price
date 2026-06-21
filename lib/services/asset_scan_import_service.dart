import '../models/asset.dart';
import 'asset_qr_service.dart';

enum AssetScanImportAction { showExisting, previewNew }

class AssetScanImportResult {
  final AssetScanImportAction action;
  final Asset asset;

  const AssetScanImportResult._({required this.action, required this.asset});

  const AssetScanImportResult.showExisting(Asset asset)
    : this._(action: AssetScanImportAction.showExisting, asset: asset);

  const AssetScanImportResult.previewNew(Asset asset)
    : this._(action: AssetScanImportAction.previewNew, asset: asset);

  bool get isExisting => action == AssetScanImportAction.showExisting;
}

class AssetScanImportService {
  const AssetScanImportService._();

  static Future<AssetScanImportResult> resolve({
    required String qrData,
    required Future<Asset?> Function(String id) findExistingById,
  }) async {
    final parsedQr = AssetQrService.parse(qrData);
    final originalId = parsedQr.originalId;

    if (originalId != null && originalId.isNotEmpty) {
      final existingAsset = await findExistingById(originalId);
      if (existingAsset != null) {
        return AssetScanImportResult.showExisting(existingAsset);
      }
    }

    return AssetScanImportResult.previewNew(parsedQr.asset);
  }
}

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../screens/asset_detail_screen.dart';
import '../screens/scanner_screen.dart';
import 'asset_scan_import_service.dart';
import 'local_db_service.dart';

class HomeScanFlow {
  const HomeScanFlow._();

  static Future<void> handleScanQRCode(BuildContext context) async {
    final status = await Permission.camera.request();
    if (!context.mounted) return;

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('需要相机权限才能扫码'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );

    if (result == null || !context.mounted) return;
    await _processScannedQRCode(context, result);
  }

  static Future<void> _processScannedQRCode(
    BuildContext context,
    String qrData,
  ) async {
    try {
      final result = await AssetScanImportService.resolve(
        qrData: qrData,
        findExistingById: LocalDbService().getAssetById,
      );
      if (!context.mounted) return;

      if (result.isExisting) {
        final asset = result.asset;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('资产已存在'),
            content: Text('「${asset.assetName}」已在您的库存中。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('确定'),
              ),
            ],
          ),
        );
        if (!context.mounted) return;

        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: asset)),
        );
        return;
      }

      final scannedAsset = result.asset;
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AssetDetailScreen(asset: scannedAsset, isPreview: true),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法识别的资产二维码'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

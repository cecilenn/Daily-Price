import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

import '../services/asset_share_service.dart';

class AssetQrShareDialog extends StatelessWidget {
  final String jsonData;

  const AssetQrShareDialog({super.key, required this.jsonData});

  @override
  Widget build(BuildContext context) {
    final screenshotController = ScreenshotController();
    final qrSize = jsonData.length > 800
        ? 300.0
        : (jsonData.length > 400 ? 280.0 : 260.0);

    return AlertDialog(
      title: const Text('分享资产'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: qrSize,
            height: qrSize,
            child: Screenshot(
              controller: screenshotController,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: QrImageView(data: jsonData, version: QrVersions.auto),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final success = await AssetShareService.saveQrToGallery(
                screenshotController,
              );
              if (context.mounted) {
                Navigator.pop(context, success);
              }
            },
            icon: const Icon(Icons.save_alt),
            label: const Text('保存到相册'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

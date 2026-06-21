import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InspectionScanOptionsSheet extends StatelessWidget {
  final VoidCallback onEntryScan;
  final VoidCallback onConfirmScan;
  final VoidCallback onManualInput;

  const InspectionScanOptionsSheet({
    super.key,
    required this.onEntryScan,
    required this.onConfirmScan,
    required this.onManualInput,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('扫码录入'),
            subtitle: const Text('添加资产到检查列表'),
            onTap: onEntryScan,
          ),
          ListTile(
            leading: const Icon(Icons.verified),
            title: const Text('扫码确认'),
            subtitle: const Text('确认检查列表中的资产'),
            onTap: onConfirmScan,
          ),
          ListTile(
            leading: const Icon(Icons.keyboard),
            title: const Text('手动输入编码'),
            subtitle: const Text('调试用：手动输入资产编码'),
            onTap: onManualInput,
          ),
        ],
      ),
    );
  }
}

class ManualAssetCodeDialog extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const ManualAssetCodeDialog({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('输入资产编码'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '例如：EQ-001',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => onSubmitted(controller.text.trim()),
          child: const Text('录入'),
        ),
      ],
    );
  }
}

class ShareCodeDialog extends StatelessWidget {
  final String shareCode;

  const ShareCodeDialog({super.key, required this.shareCode});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('上传成功'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '分享码：$shareCode',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            height: 200,
            child: QrImageView(
              data: shareCode,
              version: QrVersions.auto,
              size: 200,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '请将分享码或二维码发送给需要导入的同事',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/asset.dart';

/// ==================== 资产二维码展示页面 ====================
/// 展示资产的二维码，供其他设备扫描查看
class QrCodeScreen extends StatelessWidget {
  final Asset asset;

  const QrCodeScreen({
    super.key,
    required this.asset,
  });

  /// 构建二维码数据格式
  /// 格式: dailyprice://asset/{uuid}
  String get _qrData {
    final id = asset.id ?? '';
    return 'dailyprice://asset/$id';
  }

  @override
  Widget build(BuildContext context) {
    final id = asset.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('资产二维码'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 资产名称
                Text(
                  asset.assetName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // 资产价格
                Text(
                  '购入价格: ¥${asset.purchasePrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                // 二维码
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                    errorStateBuilder: (context, error) {
                      return const Center(
                        child: Text(
                          '二维码生成失败',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // 提示文字
                Text(
                  '扫描二维码查看资产详情',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                // ID 显示（可折叠）
                if (id.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '资产 ID',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          id,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

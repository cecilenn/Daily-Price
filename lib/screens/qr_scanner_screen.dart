import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/local_db_service.dart';
import '../models/asset.dart';
import 'asset_detail_screen.dart';

/// ==================== 二维码扫描页面 ====================
/// 扫描资产二维码，跳转至资产详情
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  /// 处理扫描结果
  Future<void> _handleScan(String? rawValue) async {
    if (_isProcessing || rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // 解析二维码数据
      // 格式: dailyprice://asset/{uuid}
      final uri = Uri.tryParse(rawValue);
      if (uri == null || !uri.scheme.startsWith('dailyprice')) {
        _showError('无效的二维码格式');
        return;
      }

      // 提取资产 ID
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty || pathSegments[0] != 'asset') {
        _showError('无效的资产二维码');
        return;
      }

      final assetId = pathSegments.length > 1 ? pathSegments[1] : '';
      if (assetId.isEmpty) {
        _showError('无法获取资产 ID');
        return;
      }

      // 查询资产
      final asset = await LocalDbService().getAssetByUuid(assetId);
      if (asset == null) {
        _showError('未找到该资产，可能已被删除');
        return;
      }

      // 跳转资产详情页
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AssetDetailScreen(asset: asset),
          ),
        );
      }
    } catch (e) {
      _showError('扫描失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// 显示错误信息
  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    // 3秒后重置错误状态，允许重新扫描
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _errorMessage = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 相机预览
          MobileScanner(
            onDetect: (capture) {
              if (_isProcessing || _errorMessage != null) return;

              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _handleScan(rawValue);
                  break;
                }
              }
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '相机启动失败',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.errorDetails?.message ?? '请检查相机权限',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // 扫描框遮罩
          _buildScanOverlay(),
          // 底部提示
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '对准资产二维码进行扫描',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          // 处理中遮罩
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建扫描框遮罩
  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.7;
        final left = (constraints.maxWidth - scanAreaSize) / 2;
        final top = (constraints.maxHeight - scanAreaSize) / 2;

        return Stack(
          children: [
            // 遮罩层
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScanOverlayPainter(
                scanAreaRect: Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
              ),
            ),
            // 扫描框边框
            Positioned(
              left: left,
              top: top,
              width: scanAreaSize,
              height: scanAreaSize,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // 四角标记
            Positioned(
              left: left - 4,
              top: top - 4,
              child: _buildCornerMarker(true, true),
            ),
            Positioned(
              left: left + scanAreaSize - 16,
              top: top - 4,
              child: _buildCornerMarker(false, true),
            ),
            Positioned(
              left: left - 4,
              top: top + scanAreaSize - 16,
              child: _buildCornerMarker(true, false),
            ),
            Positioned(
              left: left + scanAreaSize - 16,
              top: top + scanAreaSize - 16,
              child: _buildCornerMarker(false, false),
            ),
          ],
        );
      },
    );
  }

  /// 构建角标
  Widget _buildCornerMarker(bool isLeft, bool isTop) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          left: isLeft ? const BorderSide(color: Colors.blue, width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.blue, width: 4) : BorderSide.none,
          top: isTop ? const BorderSide(color: Colors.blue, width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.blue, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}

/// ==================== 扫描遮罩绘制器 ====================
class _ScanOverlayPainter extends CustomPainter {
  final Rect scanAreaRect;

  _ScanOverlayPainter({required this.scanAreaRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // 绘制遮罩（扫描框区域透明）
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanAreaRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

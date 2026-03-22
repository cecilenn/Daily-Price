import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// V2.1 扫码页面 - 防抖重构版
///
/// 独立 StatefulWidget，通过 Navigator.push 返回值传递扫码结果
/// 核心解决 MobileScanner onDetect 连续触发导致的路由崩溃问题
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // MobileScanner 控制器
  late final MobileScannerController _controller;

  // 防抖标志位：识别成功后立即锁死，防止重复触发
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 处理扫码识别结果
  void _handleBarcodeDetection(String rawValue) {
    if (_isProcessing) return;

    _isProcessing = true;

    // 停止相机扫描，避免资源浪费
    _controller.stop();

    // 返回扫码结果并关闭页面
    Navigator.pop(context, rawValue);
  }

  /// 从相册选择图片并解析二维码
  Future<void> _pickImageFromGallery() async {
    // 如果已在处理中，忽略操作
    if (_isProcessing) return;

    try {
      // 第一步：暂停相机，避免时序冲突
      await _controller.stop();

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      // 用户取消选择，恢复相机
      if (image == null) {
        await _controller.start();
        return;
      }

      // 使用 MobileScanner 分析图片中的二维码
      final BarcodeCapture? barcodeCapture = await _controller.analyzeImage(
        image.path,
      );

      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        // 分析成功，获取条码值
        final String? rawValue = barcodeCapture.barcodes.first.rawValue;
        if (rawValue != null && rawValue.isNotEmpty) {
          _handleBarcodeDetection(rawValue);
        }
      } else {
        // 图片中没有识别到二维码，弹出提示并恢复相机
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未发现有效二维码'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // 恢复相机运行
        await _controller.start();
      }
    } catch (e) {
      // 发生异常时也要恢复相机
      await _controller.start();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('相册选择失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 底层：相机预览
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              // 防抖核心逻辑
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _handleBarcodeDetection(barcodes.first.rawValue!);
              }
            },
          ),

          // 中层：半透明遮罩 + 透明扫描框
          CustomPaint(size: Size.infinite, painter: _ScannerOverlayPainter()),

          // 顶层：透明 AppBar + 操作按钮
          SafeArea(
            child: Column(
              children: [
                // 透明 AppBar
                Container(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      // 左侧：返回按钮
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        tooltip: '返回',
                      ),

                      const Spacer(),

                      // 右侧：相册按钮
                      IconButton(
                        icon: const Icon(Icons.image, color: Colors.white),
                        onPressed: _pickImageFromGallery,
                        tooltip: '从相册选择',
                      ),
                    ],
                  ),
                ),

                // 中间留白区域（扫描框位置）
                const Expanded(child: SizedBox()),

                // 底部：提示文字
                Container(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: const Text(
                    '将二维码放入框内即可自动扫描',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black54,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 扫码框遮罩绘制器
///
/// 绘制半透明黑色遮罩，中间留出一个正方形透明扫描区域
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanBoxSize = size.width * 0.7;
    final double left = (size.width - scanBoxSize) / 2;
    final double top = (size.height - scanBoxSize) / 2;

    final Rect scanRect = Rect.fromLTWH(left, top, scanBoxSize, scanBoxSize);

    // 绘制半透明遮罩（排除扫描框区域）
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // 使用 PathOperation.difference 创建镂空效果
    final Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path scanPath = Path()..addRect(scanRect);

    final Path resultPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      scanPath,
    );

    canvas.drawPath(resultPath, overlayPaint);

    // 绘制扫描框边框
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(scanRect, borderPaint);

    // 绘制四角装饰线
    final double cornerLength = scanBoxSize * 0.15;
    final double cornerWidth = 4;

    final Paint cornerPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth;

    // 左上角
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // 右上角
    canvas.drawLine(
      Offset(left + scanBoxSize - cornerLength, top),
      Offset(left + scanBoxSize, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanBoxSize, top),
      Offset(left + scanBoxSize, top + cornerLength),
      cornerPaint,
    );

    // 左下角
    canvas.drawLine(
      Offset(left, top + scanBoxSize - cornerLength),
      Offset(left, top + scanBoxSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanBoxSize),
      Offset(left + cornerLength, top + scanBoxSize),
      cornerPaint,
    );

    // 右下角
    canvas.drawLine(
      Offset(left + scanBoxSize - cornerLength, top + scanBoxSize),
      Offset(left + scanBoxSize, top + scanBoxSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanBoxSize, top + scanBoxSize - cornerLength),
      Offset(left + scanBoxSize, top + scanBoxSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

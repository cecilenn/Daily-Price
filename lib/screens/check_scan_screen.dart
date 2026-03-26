import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/check_provider.dart';
import '../models/check_session.dart';

enum ScanMode { entry, confirm }

class CheckScanScreen extends StatefulWidget {
  final String sessionId;
  final ScanMode mode;

  const CheckScanScreen({
    super.key,
    required this.sessionId,
    required this.mode,
  });

  @override
  State<CheckScanScreen> createState() => _CheckScanScreenState();
}

class _CheckScanScreenState extends State<CheckScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final List<CheckItem> _scannedItems = [];
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _isProcessing = true;
    _scannerController.stop();

    await _processBarcode(barcode.rawValue!);
    _isProcessing = false;
  }

  Future<void> _processBarcode(String rawValue) async {
    Map<String, dynamic> assetData;
    String assetId;

    try {
      assetData = jsonDecode(rawValue);
      assetId = assetData['id'] as String;
    } catch (_) {
      assetId = rawValue;
      assetData = {'id': assetId, 'assetName': '未知资产'};
    }

    if (widget.mode == ScanMode.entry) {
      await _handleEntry(assetId, assetData);
    } else {
      await _handleConfirm(assetId, assetData);
    }
  }

  Future<void> _handleEntry(
    String assetId,
    Map<String, dynamic> assetData,
  ) async {
    final assetName = assetData['assetName'] as String? ?? '未知资产';

    // 检查是否已在列表中
    final existingItems = await context.read<CheckProvider>().getItems(
      widget.sessionId,
    );
    final existing = existingItems
        .where((i) => i.assetId == assetId)
        .firstOrNull;

    if (existing != null) {
      _showMessage('⚠️ $assetName 已在检查列表中');
      await Future.delayed(const Duration(milliseconds: 800));
      _scannerController.start();
      return;
    }

    // 添加到检查列表
    final snapshotJson = jsonEncode(assetData);
    final item = await context.read<CheckProvider>().addItem(
      sessionId: widget.sessionId,
      assetId: assetId,
      assetSnapshot: snapshotJson,
    );

    setState(() {
      _scannedItems.insert(0, item);
    });

    _showAssetDetailFromSnapshot(assetData, item.id);
  }

  Future<void> _handleConfirm(
    String assetId,
    Map<String, dynamic> assetData,
  ) async {
    final assetName = assetData['assetName'] as String? ?? '未知资产';

    // 在检查列表中查找
    final existingItems = await context.read<CheckProvider>().getItems(
      widget.sessionId,
    );
    final existing = existingItems
        .where((i) => i.assetId == assetId)
        .firstOrNull;

    if (existing == null) {
      _showMessage('⚠️ $assetName 不在检查列表中');
      await Future.delayed(const Duration(milliseconds: 800));
      _scannerController.start();
      return;
    }

    if (existing.isConfirmed) {
      _showMessage('⚠️ $assetName 已确认过');
      await Future.delayed(const Duration(milliseconds: 800));
      _scannerController.start();
      return;
    }

    // 确认
    await context.read<CheckProvider>().confirmItem(existing.id);

    // 用确认后的快照数据（从 existing item 获取，而非从 QR 码）
    final confirmedSnapshotData = existing.snapshotData;

    setState(() {
      final idx = _scannedItems.indexWhere((i) => i.id == existing.id);
      if (idx >= 0) {
        // 创建更新后的 CheckItem（confirmedAt 不为 null）
        _scannedItems[idx] = CheckItem(
          id: existing.id,
          sessionId: existing.sessionId,
          assetId: existing.assetId,
          assetSnapshot: existing.assetSnapshot,
          confirmedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
    });

    // 显示详情 Sheet（确认模式）
    _showAssetDetailFromSnapshot(confirmedSnapshotData, existing.id);
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      _isProcessing = true;
      final result = await _scannerController.analyzeImage(image.path);
      if (result != null && result.barcodes.isNotEmpty) {
        final barcode = result.barcodes.first;
        if (barcode.rawValue != null) {
          await _processBarcode(barcode.rawValue!);
        }
      } else {
        if (mounted) {
          _showMessage('未识别到二维码');
        }
        _isProcessing = false;
      }
    } catch (e) {
      if (mounted) {
        _showError('识别失败：${e.toString()}');
      }
      _isProcessing = false;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAssetDetailFromSnapshot(
    Map<String, dynamic> data,
    String checkItemId,
  ) {
    final assetName = data['assetName'] as String? ?? '未知资产';
    final purchasePrice = data['purchasePrice'];
    final purchaseDate = data['purchaseDate'] as int?;
    final category = data['category'] as String?;
    final status = data['status'] as int?;
    final tags = data['tags'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 拖拽手柄
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        assetName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 详情列表
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (purchasePrice != null)
                        _buildDetailItem(
                          '购入价格',
                          '¥${(purchasePrice as num).toStringAsFixed(2)}',
                        ),
                      if (purchaseDate != null)
                        _buildDetailItem(
                          '购买日期',
                          _formatTimestamp(purchaseDate),
                        ),
                      if (category != null && category.isNotEmpty)
                        _buildDetailItem('分类', category),
                      if (status != null)
                        _buildDetailItem(
                          '状态',
                          status == 0
                              ? '服役中'
                              : status == 1
                              ? '已退役'
                              : '已卖出',
                        ),
                      if (tags is List && (tags as List).isNotEmpty)
                        _buildDetailItem('标签', (tags as List).join(', ')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) _scannerController.start();
    });
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  bool _isItemConfirmed(String checkItemId) {
    final item = _scannedItems.firstWhere(
      (item) => item.id == checkItemId,
      orElse: () => CheckItem(
        id: '',
        sessionId: '',
        assetId: '',
        assetSnapshot: '',
        confirmedAt: null,
      ),
    );
    return item.isConfirmed;
  }

  void _finishScanning() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == ScanMode.entry ? '扫码录入' : '扫码确认'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: _pickImageFromGallery,
            tooltip: '从相册识别',
          ),
          TextButton(onPressed: _finishScanning, child: const Text('完成')),
        ],
      ),
      body: Column(
        children: [
          // 相机预览区域
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),
          // 扫码结果区域
          Expanded(flex: 2, child: _buildScanResultArea()),
          // 底部统计
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '已扫描：${_scannedItems.length} 个资产',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResultArea() {
    if (_scannedItems.isEmpty) {
      return const Center(child: Text('请扫描资产二维码'));
    }

    return PageView.builder(
      itemCount: _scannedItems.length,
      // 注意：不在 onPageChanged 中自动确认，确认只通过扫码触发
      itemBuilder: (context, index) {
        final item = _scannedItems[index];
        return _buildAssetCard(item);
      },
    );
  }

  Widget _buildAssetCard(CheckItem item) {
    final snapshotData = item.snapshotData;
    final assetName = item.assetName;
    final isConfirmed = item.isConfirmed;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assetName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  isConfirmed ? Icons.check_circle : Icons.circle_outlined,
                  color: isConfirmed ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 从 JSON 快照展示关键信息
            if (snapshotData['purchasePrice'] != null)
              Text(
                '¥${(snapshotData['purchasePrice'] as num).toStringAsFixed(2)}',
              ),
            if (snapshotData['category'] != null)
              Text(snapshotData['category'].toString()),
          ],
        ),
      ),
    );
  }
}

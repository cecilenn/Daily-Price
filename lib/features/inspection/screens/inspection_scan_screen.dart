import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/inspection_provider.dart';
import '../models/company_check_item.dart';

enum InspectionScanMode { entry, confirm }

class InspectionScanScreen extends StatefulWidget {
  final String sessionId;
  final InspectionScanMode mode;

  const InspectionScanScreen({
    super.key,
    required this.sessionId,
    required this.mode,
  });

  @override
  State<InspectionScanScreen> createState() => _InspectionScanScreenState();
}

class _InspectionScanScreenState extends State<InspectionScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final List<CompanyCheckItem> _scannedItems = [];
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

  /// 解析扫码结果，提取资产编码
  /// 支持：纯文本编码、JSON（含"资产编码"字段）
  String _parseAssetCode(String rawValue) {
    try {
      final data = jsonDecode(rawValue);
      if (data is Map<String, dynamic>) {
        return (data['资产编码'] ?? data['assetCode'] ?? data['id'])
            .toString();
      }
    } catch (_) {}
    // 纯文本当作资产编码
    return rawValue.trim();
  }

  Future<void> _processBarcode(String rawValue) async {
    final assetCode = _parseAssetCode(rawValue);

    if (widget.mode == InspectionScanMode.entry) {
      await _handleEntry(assetCode);
    } else {
      await _handleConfirm(assetCode);
    }
  }

  Future<void> _handleEntry(String assetCode) async {
    final provider = context.read<InspectionProvider>();

    // 检查是否已在列表中
    final existingItems = await provider.getItems(widget.sessionId);
    final existing = existingItems
        .where((i) => i.assetCode == assetCode)
        .firstOrNull;

    if (existing != null) {
      _showMessage('⚠️ $assetCode 已在检查列表中');
      await Future.delayed(const Duration(milliseconds: 800));
      _scannerController.start();
      return;
    }

    // 从本地总资产库查找
    final asset = await provider.lookupAsset(assetCode);
    String assetSnapshot;
    if (asset != null) {
      assetSnapshot = jsonEncode(asset.toSnapshotJson());
    } else {
      assetSnapshot = jsonEncode({
        'assetCode': assetCode,
        'assetName': '未知资产（本地库未找到）',
      });
      _showMessage('⚠️ 资产编码不在本地库中，已添加为未知资产');
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 添加到检查列表
    final item = await provider.addItem(
      sessionId: widget.sessionId,
      assetCode: assetCode,
      assetSnapshot: assetSnapshot,
    );

    setState(() {
      _scannedItems.insert(0, item);
    });

    _showAssetDetail(item);
  }

  Future<void> _handleConfirm(String assetCode) async {
    final provider = context.read<InspectionProvider>();

    // 在检查列表中查找
    final existingItems = await provider.getItems(widget.sessionId);
    final existing = existingItems
        .where((i) => i.assetCode == assetCode)
        .firstOrNull;

    if (existing == null) {
      _showMessage('⚠️ $assetCode 不在检查列表中');
      await Future.delayed(const Duration(milliseconds: 800));
      _scannerController.start();
      return;
    }

    if (existing.isConfirmed) {
      _showMessage('⚠️ ${existing.assetName} 已确认过');
      await Future.delayed(const Duration(milliseconds: 800));
      _scannerController.start();
      return;
    }

    // 确认
    await provider.confirmItem(existing.id);

    // 更新本地扫描列表中的状态
    final updatedItem = CompanyCheckItem(
      id: existing.id,
      sessionId: existing.sessionId,
      assetCode: existing.assetCode,
      assetSnapshot: existing.assetSnapshot,
      confirmedAt: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      final idx = _scannedItems.indexWhere((i) => i.id == existing.id);
      if (idx >= 0) {
        _scannedItems[idx] = updatedItem;
      } else {
        _scannedItems.insert(0, updatedItem);
      }
    });

    _showAssetDetail(updatedItem);
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
        if (mounted) _showMessage('未识别到二维码');
        _isProcessing = false;
      }
    } catch (e) {
      if (mounted) _showError('识别失败：${e.toString()}');
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

  void _showAssetDetail(CompanyCheckItem item) {
    final snapshot = item.snapshotData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.assetName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      item.isConfirmed
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color:
                          item.isConfirmed ? Colors.green : Colors.red,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('资产编码', item.assetCode),
                      if (snapshot['spec'] != null &&
                          snapshot['spec'].toString().isNotEmpty)
                        _buildDetailItem(
                            '规格型号', snapshot['spec']),
                      if (snapshot['department'] != null &&
                          snapshot['department']
                              .toString()
                              .isNotEmpty)
                        _buildDetailItem(
                            '使用部门', snapshot['department']),
                      if (snapshot['user'] != null &&
                          snapshot['user'].toString().isNotEmpty)
                        _buildDetailItem(
                            '使用人', snapshot['user']),
                      if (snapshot['location'] != null &&
                          snapshot['location']
                              .toString()
                              .isNotEmpty)
                        _buildDetailItem(
                            '存放位置', snapshot['location']),
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finishScanning() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == InspectionScanMode.entry
              ? '扫码录入'
              : '扫码确认',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: _pickImageFromGallery,
            tooltip: '从相册识别',
          ),
          TextButton(
            onPressed: _finishScanning,
            child: const Text('完成'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),
          Expanded(flex: 2, child: _buildScanResultArea()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '已扫描：${_scannedItems.length} 个资产',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
      itemBuilder: (context, index) {
        final item = _scannedItems[index];
        return _buildAssetCard(item);
      },
    );
  }

  Widget _buildAssetCard(CompanyCheckItem item) {
    final snapshot = item.snapshotData;

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
                    item.assetName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  item.isConfirmed
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color:
                      item.isConfirmed ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('资产编码: ${item.assetCode}'),
            if (snapshot['spec'] != null &&
                snapshot['spec'].toString().isNotEmpty)
              Text('规格型号: ${snapshot['spec']}'),
            if (snapshot['department'] != null &&
                snapshot['department'].toString().isNotEmpty)
              Text('使用部门: ${snapshot['department']}'),
          ],
        ),
      ),
    );
  }
}

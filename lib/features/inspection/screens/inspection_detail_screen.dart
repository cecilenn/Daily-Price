import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/inspection_provider.dart';
import '../models/company_check_session.dart';
import '../models/company_check_item.dart';
import '../data/inspection_db.dart';
import 'inspection_scan_screen.dart';

class InspectionDetailScreen extends StatefulWidget {
  final String sessionId;

  const InspectionDetailScreen({super.key, required this.sessionId});

  @override
  State<InspectionDetailScreen> createState() =>
      _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  late Future<CompanyCheckSession?> _sessionFuture;
  late Future<List<CompanyCheckItem>> _itemsFuture;
  int _filter = 0; // 0=全部, 1=已确认, 2=未确认
  bool _isMultiSelectMode = false;
  final Set<String> _selectedItemIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final provider = context.read<InspectionProvider>();
    _sessionFuture = InspectionDb().getSession(widget.sessionId);
    _itemsFuture = provider.getItems(widget.sessionId);
  }

  void _refresh() {
    setState(() => _loadData());
  }

  void _enterMultiSelectMode(String itemId) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedItemIds.add(itemId);
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedItemIds.clear();
    });
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('扫码录入'),
              subtitle: const Text('添加资产到检查列表'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InspectionScanScreen(
                      sessionId: widget.sessionId,
                      mode: InspectionScanMode.entry,
                    ),
                  ),
                ).then((_) => _refresh());
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified),
              title: const Text('扫码确认'),
              subtitle: const Text('确认检查列表中的资产'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InspectionScanScreen(
                      sessionId: widget.sessionId,
                      mode: InspectionScanMode.confirm,
                    ),
                  ),
                ).then((_) => _refresh());
              },
            ),
            ListTile(
              leading: const Icon(Icons.keyboard),
              title: const Text('手动输入编码'),
              subtitle: const Text('调试用：手动输入资产编码'),
              onTap: () {
                Navigator.pop(ctx);
                _showManualInputDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              await _manualAddAsset(code);
            },
            child: const Text('录入'),
          ),
        ],
      ),
    );
  }

  Future<void> _manualAddAsset(String assetCode) async {
    final provider = context.read<InspectionProvider>();

    // 检查是否已存在
    final existingItems = await provider.getItems(widget.sessionId);
    if (existingItems.any((i) => i.assetCode == assetCode)) {
      _showError('$assetCode 已在检查列表中');
      return;
    }

    // 从本地资产库查找
    final asset = await provider.lookupAsset(assetCode);
    String assetSnapshot;
    if (asset != null) {
      assetSnapshot = jsonEncode(asset.toSnapshotJson());
    } else {
      assetSnapshot = jsonEncode({
        'assetCode': assetCode,
        'assetName': '未知资产',
      });
    }

    await provider.addItem(
      sessionId: widget.sessionId,
      assetCode: assetCode,
      assetSnapshot: assetSnapshot,
    );
    _refresh();
    _showSuccess('已添加 $assetCode');
  }

  void _toggleSessionStatus() async {
    final session = await _sessionFuture;
    if (session == null) return;

    final newStatus = session.status == 0 ? 1 : 0;
    await InspectionDb().updateSessionStatus(widget.sessionId, newStatus);
    _refresh();
    _showSuccess(newStatus == 1 ? '检查已完成' : '检查已重新打开');
  }

  Future<void> _uploadSession() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在上传...'),
          duration: Duration(seconds: 2),
        ),
      );
      final shareCode = await context
          .read<InspectionProvider>()
          .uploadSession(widget.sessionId);
      if (mounted) _showShareCodeDialog(shareCode);
    } catch (e) {
      if (mounted) _showError('上传失败：${e.toString()}');
    }
  }

  void _showShareCodeDialog(String shareCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitMultiSelectMode,
              )
            : null,
        title: _isMultiSelectMode
            ? Text('已选 ${_selectedItemIds.length} 项')
            : FutureBuilder<CompanyCheckSession?>(
                future: _sessionFuture,
                builder: (context, snapshot) {
                  final session = snapshot.data;
                  return Text(session?.name ?? '检查详情');
                },
              ),
        centerTitle: true,
        actions: _isMultiSelectMode
            ? [
                FutureBuilder<List<CompanyCheckItem>>(
                  future: _itemsFuture,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    return IconButton(
                      icon: Icon(
                        _selectedItemIds.length == items.length
                            ? Icons.deselect
                            : Icons.select_all,
                      ),
                      tooltip: _selectedItemIds.length == items.length
                          ? '取消全选'
                          : '全选',
                      onPressed: () {
                        setState(() {
                          if (_selectedItemIds.length == items.length) {
                            _selectedItemIds.clear();
                          } else {
                            _selectedItemIds.clear();
                            _selectedItemIds.addAll(items.map((i) => i.id));
                          }
                        });
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '删除',
                  onPressed:
                      _selectedItemIds.isNotEmpty ? _batchDelete : null,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  onPressed: _uploadSession,
                  tooltip: '上传到云端',
                ),
                FutureBuilder<CompanyCheckSession?>(
                  future: _sessionFuture,
                  builder: (context, snapshot) {
                    final session = snapshot.data;
                    final isCompleted = session?.status == 1;
                    return IconButton(
                      icon: Icon(isCompleted ? Icons.lock_open : Icons.check),
                      tooltip: isCompleted ? '重新打开' : '完成检查',
                      onPressed: _toggleSessionStatus,
                    );
                  },
                ),
              ],
      ),
      body: FutureBuilder<CompanyCheckSession?>(
        future: _sessionFuture,
        builder: (context, sessionSnapshot) {
          if (sessionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final session = sessionSnapshot.data;
          if (session == null) {
            return const Center(child: Text('检查任务不存在'));
          }

          return Column(
            children: [
              // 进度指示器
              FutureBuilder<List<CompanyCheckItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  final confirmed =
                      items.where((i) => i.isConfirmed).length;
                  final total = items.length;
                  final progress =
                      total > 0 ? confirmed / total : 0.0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '检查进度',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '$confirmed / $total',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress == 1.0 ? Colors.green : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // 筛选栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('全部'),
                      selected: _filter == 0,
                      onSelected: (selected) {
                        if (selected) setState(() => _filter = 0);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('已确认'),
                      selected: _filter == 1,
                      onSelected: (selected) {
                        if (selected) setState(() => _filter = 1);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('未确认'),
                      selected: _filter == 2,
                      onSelected: (selected) {
                        if (selected) setState(() => _filter = 2);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 检查项列表
              Expanded(
                child: FutureBuilder<List<CompanyCheckItem>>(
                  future: _itemsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final items = snapshot.data ?? [];
                    final filteredItems = items.where((item) {
                      if (_filter == 1) return item.isConfirmed;
                      if (_filter == 2) return !item.isConfirmed;
                      return true;
                    }).toList();

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Text(
                          _filter == 0
                              ? '暂无检查项，请扫码录入'
                              : '没有匹配的检查项',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildCheckItemCard(item);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<CompanyCheckSession?>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          final session = snapshot.data;
          if (session == null || session.status == 1) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: _showScanOptions,
            child: const Icon(Icons.qr_code_scanner),
          );
        },
      ),
      bottomSheet:
          _isMultiSelectMode ? _buildMultiSelectBottomSheet() : null,
    );
  }

  Widget _buildMultiSelectBottomSheet() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.check_circle,
              label: '标记已确认',
              color: Colors.green,
              onPressed:
                  _selectedItemIds.isEmpty ? null : _batchConfirm,
            ),
            _buildActionButton(
              icon: Icons.remove_circle_outline,
              label: '取消确认',
              color: Colors.orange,
              onPressed:
                  _selectedItemIds.isEmpty ? null : _batchUnconfirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  void _batchConfirm() async {
    final provider = context.read<InspectionProvider>();
    for (final id in _selectedItemIds) {
      await provider.confirmItem(id);
    }
    if (mounted) {
      _exitMultiSelectMode();
      _refresh();
      _showSuccess('已确认 ${_selectedItemIds.length} 项');
    }
  }

  void _batchUnconfirm() async {
    final provider = context.read<InspectionProvider>();
    final items = await _itemsFuture;
    int count = 0;
    for (final id in _selectedItemIds) {
      final item = items.firstWhere((i) => i.id == id);
      if (item.isConfirmed) {
        await provider.unconfirmItem(id);
        count++;
      }
    }
    if (mounted) {
      _exitMultiSelectMode();
      _refresh();
      _showSuccess('已取消确认 $count 项');
    }
  }

  void _batchDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text(
          '确定要删除选中的 ${_selectedItemIds.length} 个检查项吗？\n此操作不可恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final provider = context.read<InspectionProvider>();
              for (final id in _selectedItemIds) {
                await provider.deleteItem(id);
              }
              _exitMultiSelectMode();
              if (context.mounted) Navigator.pop(context);
              _refresh();
              _showSuccess('已删除 ${_selectedItemIds.length} 个检查项');
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItemCard(CompanyCheckItem item) {
    final isSelected = _selectedItemIds.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isMultiSelectMode && isSelected
            ? [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: _isMultiSelectMode && isSelected
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2.5,
              )
            : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            item.isConfirmed
                ? Icons.check_circle
                : Icons.circle_outlined,
            color: item.isConfirmed ? Colors.green : Colors.red,
          ),
          title: Text(item.assetName),
          subtitle: Text(
            '资产编码: ${item.assetCode}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () {
            if (_isMultiSelectMode) {
              _toggleItemSelection(item.id);
            } else {
              _showAssetDetail(item);
            }
          },
          onLongPress: () {
            if (!_isMultiSelectMode) {
              _enterMultiSelectMode(item.id);
            }
          },
        ),
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
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.assetName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                item.isConfirmed
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 16,
                                color: item.isConfirmed
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.isConfirmed ? '已确认' : '未确认',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: item.isConfirmed
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                        _buildDetailItem('规格型号', snapshot['spec']),
                      if (snapshot['department'] != null &&
                          snapshot['department'].toString().isNotEmpty)
                        _buildDetailItem('使用部门', snapshot['department']),
                      if (snapshot['user'] != null &&
                          snapshot['user'].toString().isNotEmpty)
                        _buildDetailItem('使用人', snapshot['user']),
                      if (snapshot['location'] != null &&
                          snapshot['location'].toString().isNotEmpty)
                        _buildDetailItem('存放位置', snapshot['location']),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}

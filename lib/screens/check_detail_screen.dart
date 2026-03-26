import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:csv/csv.dart';
import '../providers/check_provider.dart';
import '../models/check_session.dart';
import '../services/local_db_service.dart';
import 'check_scan_screen.dart';

class CheckDetailScreen extends StatefulWidget {
  final String sessionId;

  const CheckDetailScreen({super.key, required this.sessionId});

  @override
  State<CheckDetailScreen> createState() => _CheckDetailScreenState();
}

class _CheckDetailScreenState extends State<CheckDetailScreen> {
  late Future<CheckSession?> _sessionFuture;
  late Future<List<CheckItem>> _itemsFuture;
  int _filter = 0; // 0=全部, 1=已确认, 2=未确认
  bool _isMultiSelectMode = false;
  final Set<String> _selectedItemIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final provider = context.read<CheckProvider>();
    _sessionFuture = _getSession(provider);
    _itemsFuture = provider.getItems(widget.sessionId);
  }

  Future<CheckSession?> _getSession(CheckProvider provider) async {
    // 从本地数据库获取会话
    return await LocalDbService().getCheckSession(widget.sessionId);
  }

  void _refresh() {
    setState(() {
      _loadData();
    });
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
        if (_selectedItemIds.isEmpty) _exitMultiSelectMode();
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
                    builder: (_) => CheckScanScreen(
                      sessionId: widget.sessionId,
                      mode: ScanMode.entry,
                    ),
                  ),
                ).then((_) => _loadData());
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
                    builder: (_) => CheckScanScreen(
                      sessionId: widget.sessionId,
                      mode: ScanMode.confirm,
                    ),
                  ),
                ).then((_) => _loadData());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSessionStatus() async {
    final session = await _sessionFuture;
    if (session == null) return;

    final newStatus = session.status == 0 ? 1 : 0;
    await LocalDbService().updateCheckSessionStatus(
      widget.sessionId,
      newStatus,
    );
    _refresh();
    _showSuccess(newStatus == 1 ? '检查已完成' : '检查已重新打开');
  }

  void _exportSession() async {
    try {
      final data = await context.read<CheckProvider>().exportSession(
        widget.sessionId,
      );
      final session = data['session'] as Map<String, dynamic>;
      final items = data['items'] as List;

      final csvRows = <List<dynamic>>[
        [
          'session_id',
          'session_name',
          'session_status',
          'created_at',
          'asset_id',
          'asset_name',
          'purchase_price',
          'category',
          'status',
          'confirmed_at',
        ],
      ];

      for (final item in items) {
        final snapshot = jsonDecode(item['asset_snapshot'] as String);
        csvRows.add([
          session['id'],
          session['name'],
          session['status'],
          session['created_at'],
          item['asset_id'],
          snapshot['assetName'] ?? '',
          snapshot['purchasePrice'] ?? '',
          snapshot['category'] ?? '',
          snapshot['status'] ?? '',
          item['confirmed_at'] ?? '',
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvRows);

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultFileName =
          'check_${session['name'] ?? 'unknown'}_$timestamp.csv';

      if (kIsWeb) {
        // Web 平台下载
        final bytes = utf8.encode(csvString);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', defaultFileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSuccess('已导出检查任务');
      } else if (Platform.isAndroid) {
        // Android 平台
        try {
          final savePath = await FilePicker.platform.saveFile(
            dialogTitle: '保存检查任务',
            fileName: defaultFileName,
            type: FileType.custom,
            allowedExtensions: ['csv'],
            bytes: Uint8List.fromList(utf8.encode(csvString)),
          );

          if (savePath != null && savePath.isNotEmpty) {
            _showSuccess('已保存到：$savePath');
          }
        } catch (e) {
          // 备选方案：保存到临时目录
          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/$defaultFileName';
          final file = File(filePath);
          await file.writeAsString(csvString);
          _showSuccess('已保存到临时目录：$defaultFileName');
        }
      } else {
        // 桌面平台
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: '保存检查任务',
          fileName: defaultFileName,
          type: FileType.custom,
          allowedExtensions: ['csv'],
          bytes: Uint8List.fromList(utf8.encode(csvString)),
        );

        if (savePath != null && savePath.isNotEmpty) {
          _showSuccess('已保存到：$savePath');
        }
      }
    } catch (e) {
      _showError('导出失败：${e.toString()}');
    }
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
            : FutureBuilder<CheckSession?>(
                future: _sessionFuture,
                builder: (context, snapshot) {
                  final session = snapshot.data;
                  return Text(session?.name ?? '检查详情');
                },
              ),
        centerTitle: true,
        actions: _isMultiSelectMode
            ? [
                IconButton(
                  icon: const Icon(Icons.check_circle),
                  onPressed: _selectedItemIds.isNotEmpty ? _batchConfirm : null,
                  tooltip: '标记已确认',
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _selectedItemIds.isNotEmpty
                      ? _batchUnconfirm
                      : null,
                  tooltip: '取消确认',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _exportSession,
                ),
                FutureBuilder<CheckSession?>(
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
      body: FutureBuilder<CheckSession?>(
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
              FutureBuilder<List<CheckItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  final confirmed = items.where((i) => i.isConfirmed).length;
                  final total = items.length;
                  final progress = total > 0 ? confirmed / total : 0.0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                child: FutureBuilder<List<CheckItem>>(
                  future: _itemsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data ?? [];
                    final filteredItems = items.where((item) {
                      if (_filter == 1) return item.isConfirmed;
                      if (_filter == 2) return !item.isConfirmed;
                      return true;
                    }).toList();

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Text(_filter == 0 ? '暂无检查项' : '没有匹配的检查项'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      floatingActionButton: FutureBuilder<CheckSession?>(
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
      bottomSheet: _isMultiSelectMode ? _buildMultiSelectBottomSheet() : null,
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
              onPressed: _selectedItemIds.isEmpty ? null : _batchConfirm,
            ),
            _buildActionButton(
              icon: Icons.remove_circle_outline,
              label: '取消确认',
              color: Colors.orange,
              onPressed: _selectedItemIds.isEmpty ? null : _batchUnconfirm,
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
    final provider = context.read<CheckProvider>();
    int confirmedCount = 0;

    for (final itemId in _selectedItemIds) {
      await provider.confirmItem(itemId);
      confirmedCount++;
    }

    if (mounted) {
      _exitMultiSelectMode();
      _refresh();
      _showSuccess('已确认 $confirmedCount 项');
    }
  }

  void _batchUnconfirm() async {
    final provider = context.read<CheckProvider>();
    int unconfirmedCount = 0;

    for (final id in _selectedItemIds) {
      final items = await _itemsFuture;
      final item = items.firstWhere((i) => i.id == id);
      if (item.isConfirmed) {
        await provider.unconfirmItem(id);
        unconfirmedCount++;
      }
    }

    if (mounted) {
      _exitMultiSelectMode();
      _refresh();
      _showSuccess('已取消确认 $unconfirmedCount 项');
    }
  }

  void _batchDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${_selectedItemIds.length} 个检查项吗？\n此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final provider = context.read<CheckProvider>();
              for (final itemId in _selectedItemIds) {
                await provider.deleteItem(itemId);
              }
              _exitMultiSelectMode();
              if (mounted) Navigator.pop(context);
              _refresh();
              _showSuccess('已删除 ${_selectedItemIds.length} 个检查项');
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItemCard(CheckItem item) {
    final isSelected = _selectedItemIds.contains(item.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _isMultiSelectMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) {
                  _toggleItemSelection(item.id);
                },
              )
            : Icon(
                item.isConfirmed ? Icons.check_circle : Icons.circle_outlined,
                color: item.isConfirmed ? Colors.green : Colors.red,
              ),
        title: Text(item.assetName),
        subtitle: Text(
          '资产ID: ${item.assetId}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            context.read<CheckProvider>().deleteItem(item.id);
            _refresh();
          },
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
    );
  }

  void _showAssetDetail(CheckItem item) {
    final snapshotData = item.snapshotData;
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
                              if (item.isConfirmed &&
                                  item.confirmedAt != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(item.confirmedAt!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
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
              // 资产详情
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: _buildAssetDetailContent(snapshotData),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetDetailContent(Map<String, dynamic> snapshotData) {
    final items = <Widget>[];

    if (snapshotData.containsKey('purchasePrice') &&
        snapshotData['purchasePrice'] != null) {
      items.add(_buildDetailItem('购入价格', '¥${snapshotData['purchasePrice']}'));
    }
    if (snapshotData.containsKey('purchaseDate') &&
        snapshotData['purchaseDate'] != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        snapshotData['purchaseDate'],
      );
      items.add(
        _buildDetailItem(
          '购买日期',
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        ),
      );
    }
    if (snapshotData.containsKey('category') &&
        snapshotData['category'] != null) {
      items.add(_buildDetailItem('分类', snapshotData['category']));
    }
    if (snapshotData.containsKey('status') && snapshotData['status'] != null) {
      final status = snapshotData['status'];
      final statusText = status == 0
          ? '服役中'
          : status == 1
          ? '已退役'
          : '已卖出';
      items.add(_buildDetailItem('状态', statusText));
    }
    if (snapshotData.containsKey('expectedLifespanDays') &&
        snapshotData['expectedLifespanDays'] != null) {
      items.add(
        _buildDetailItem('预期寿命', '${snapshotData['expectedLifespanDays']} 天'),
      );
    }
    if (snapshotData.containsKey('soldPrice') &&
        snapshotData['soldPrice'] != null) {
      items.add(_buildDetailItem('卖出价格', '¥${snapshotData['soldPrice']}'));
    }
    if (snapshotData.containsKey('tags') && snapshotData['tags'] != null) {
      final tags = snapshotData['tags'];
      if (tags is List && tags.isNotEmpty) {
        items.add(_buildDetailItem('标签', tags.join(', ')));
      }
    }

    if (items.isEmpty) {
      return const Center(
        child: Text('暂无详细信息', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
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

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inspection_provider.dart';
import '../models/company_check_session.dart';
import '../models/company_check_item.dart';
import '../data/inspection_db.dart';
import '../widgets/inspection_detail_dialogs.dart';
import '../widgets/inspection_detail_widgets.dart';
import 'inspection_scan_screen.dart';

class InspectionDetailScreen extends StatefulWidget {
  final String sessionId;

  const InspectionDetailScreen({super.key, required this.sessionId});

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
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
      builder: (ctx) => InspectionScanOptionsSheet(
        onEntryScan: () => _openScanScreen(ctx, InspectionScanMode.entry),
        onConfirmScan: () => _openScanScreen(ctx, InspectionScanMode.confirm),
        onManualInput: () {
          Navigator.pop(ctx);
          _showManualInputDialog();
        },
      ),
    );
  }

  void _openScanScreen(BuildContext sheetContext, InspectionScanMode mode) {
    Navigator.pop(sheetContext);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            InspectionScanScreen(sessionId: widget.sessionId, mode: mode),
      ),
    ).then((_) {
      if (mounted) _refresh();
    });
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => ManualAssetCodeDialog(
        controller: controller,
        onSubmitted: (code) async {
          if (code.isEmpty) return;
          Navigator.pop(ctx);
          await _manualAddAsset(code);
        },
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
      assetSnapshot = jsonEncode({'assetCode': assetCode, 'assetName': '未知资产'});
    }

    await provider.addItem(
      sessionId: widget.sessionId,
      assetCode: assetCode,
      assetSnapshot: assetSnapshot,
    );
    if (!mounted) return;
    _refresh();
    _showSuccess('已添加 $assetCode');
  }

  void _toggleSessionStatus() async {
    final session = await _sessionFuture;
    if (session == null) return;

    final newStatus = session.status == 0 ? 1 : 0;
    await InspectionDb().updateSessionStatus(widget.sessionId, newStatus);
    if (!mounted) return;
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
      final shareCode = await context.read<InspectionProvider>().uploadSession(
        widget.sessionId,
      );
      if (mounted) _showShareCodeDialog(shareCode);
    } catch (e) {
      if (mounted) _showError('上传失败：${e.toString()}');
    }
  }

  void _showShareCodeDialog(String shareCode) {
    showDialog(
      context: context,
      builder: (ctx) => ShareCodeDialog(shareCode: shareCode),
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
                  onPressed: _selectedItemIds.isNotEmpty ? _batchDelete : null,
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
              FutureBuilder<List<CompanyCheckItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  return InspectionProgressHeader(items: items);
                },
              ),
              InspectionFilterBar(
                filter: _filter,
                onFilterChanged: (filter) => setState(() => _filter = filter),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<CompanyCheckItem>>(
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
                        child: Text(_filter == 0 ? '暂无检查项，请扫码录入' : '没有匹配的检查项'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return InspectionCheckItemCard(
                          item: item,
                          isMultiSelectMode: _isMultiSelectMode,
                          isSelected: _selectedItemIds.contains(item.id),
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
                        );
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
      bottomSheet: _isMultiSelectMode
          ? InspectionMultiSelectBottomSheet(
              hasSelection: _selectedItemIds.isNotEmpty,
              onConfirm: _batchConfirm,
              onUnconfirm: _batchUnconfirm,
            )
          : null,
    );
  }

  void _batchConfirm() async {
    final provider = context.read<InspectionProvider>();
    final count = _selectedItemIds.length;
    for (final id in _selectedItemIds) {
      await provider.confirmItem(id);
    }
    if (mounted) {
      _exitMultiSelectMode();
      _refresh();
      _showSuccess('已确认 $count 项');
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
    final count = _selectedItemIds.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 $count 个检查项吗？\n此操作不可恢复。'),
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
              _showSuccess('已删除 $count 个检查项');
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showAssetDetail(CompanyCheckItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => InspectionAssetDetailSheet(
          item: item,
          scrollController: scrollController,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }
}

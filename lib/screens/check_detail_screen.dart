import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/check_provider.dart';
import '../models/check_session.dart';
import '../services/asset_export_service.dart';
import '../services/check_session_archive_service.dart';
import '../services/local_db_service.dart';
import '../widgets/check_detail_widgets.dart';
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
      // 每次刷新时创建新的 futures，确保 FutureBuilder 重新执行
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
                    builder: (_) => CheckScanScreen(
                      sessionId: widget.sessionId,
                      mode: ScanMode.confirm,
                    ),
                  ),
                ).then((_) => _refresh());
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
      final csvString = CheckSessionArchiveService.encodeExportData(data);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultFileName =
          'check_${session['name'] ?? 'unknown'}_$timestamp.csv';
      final result = await AssetExportService.saveCsv(
        csvString: csvString,
        defaultFileName: defaultFileName,
      );

      if (!mounted || result.isCanceled) return;

      if (result.isUnsupported) {
        _showError(result.errorMessage ?? '当前平台不支持导出');
        return;
      }

      if (result.isSaved) {
        _showSuccess('已保存到：${result.savePath}');
        return;
      }

      if (result.errorMessage != null) {
        _showError(result.errorMessage!);
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
                FutureBuilder<List<CheckItem>>(
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
              FutureBuilder<List<CheckItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  return CheckProgressHeader(items: snapshot.data ?? []);
                },
              ),
              CheckFilterBar(
                filter: _filter,
                onFilterChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 8),
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
                        return CheckItemCard(
                          item: item,
                          isSelected: _selectedItemIds.contains(item.id),
                          isMultiSelectMode: _isMultiSelectMode,
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
      bottomSheet: _isMultiSelectMode
          ? CheckMultiSelectActionSheet(
              hasSelection: _selectedItemIds.isNotEmpty,
              onConfirm: _batchConfirm,
              onUnconfirm: _batchUnconfirm,
            )
          : null,
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
    final rootContext = context;
    final selectedCount = _selectedItemIds.length;
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 $selectedCount 个检查项吗？\n此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final provider = rootContext.read<CheckProvider>();
              for (final itemId in _selectedItemIds) {
                await provider.deleteItem(itemId);
              }
              _exitMultiSelectMode();
              if (mounted && dialogContext.mounted) {
                Navigator.pop(dialogContext);
                _refresh();
                _showSuccess('已删除 $selectedCount 个检查项');
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showAssetDetail(CheckItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => CheckAssetDetailSheet(
          item: item,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

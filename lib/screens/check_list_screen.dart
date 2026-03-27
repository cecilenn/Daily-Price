import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:csv/csv.dart';
import '../providers/check_provider.dart';
import '../models/check_session.dart';
import 'check_detail_screen.dart';

class CheckListScreen extends StatefulWidget {
  const CheckListScreen({super.key});

  @override
  State<CheckListScreen> createState() => _CheckListScreenState();
}

class _CheckListScreenState extends State<CheckListScreen> {
  bool _isMultiSelectMode = false;
  final Set<String> _selectedSessionIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckProvider>().loadSessions();
    });
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedSessionIds.clear();
      }
    });
  }

  void _toggleSessionSelection(String sessionId) {
    setState(() {
      if (_selectedSessionIds.contains(sessionId)) {
        _selectedSessionIds.remove(sessionId);
      } else {
        _selectedSessionIds.add(sessionId);
      }
    });
  }

  void _selectAll() {
    final sessions = context.read<CheckProvider>().sessions;
    setState(() {
      if (_selectedSessionIds.length == sessions.length) {
        _selectedSessionIds.clear();
      } else {
        _selectedSessionIds.addAll(sessions.map((s) => s.id));
      }
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedSessionIds.clear();
    });
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建检查任务'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '任务名称',
            hintText: '例如：2024年春季展会盘点',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final session = await context
                    .read<CheckProvider>()
                    .createSession(name);
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckDetailScreen(sessionId: session.id),
                    ),
                  ).then((_) {
                    // 从详情页返回时刷新列表（可能修改了完成状态）
                    context.read<CheckProvider>().loadSessions();
                  });
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _renameSession(String sessionId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名检查任务'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新名称',
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
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                await context.read<CheckProvider>().renameSession(
                  sessionId,
                  newName,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isMultiSelectMode
            ? Text('已选择 ${_selectedSessionIds.length} 项')
            : const Text('检查记录'),
        centerTitle: true,
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleMultiSelectMode,
              )
            : null,
        actions: _isMultiSelectMode
            ? [
                Builder(
                  builder: (context) {
                    final provider = context.watch<CheckProvider>();
                    return IconButton(
                      icon: Icon(
                        _selectedSessionIds.length == provider.sessions.length
                            ? Icons.deselect
                            : Icons.select_all,
                      ),
                      onPressed: _selectAll,
                      tooltip:
                          _selectedSessionIds.length == provider.sessions.length
                          ? '取消全选'
                          : '全选',
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _selectedSessionIds.isEmpty ? null : _batchShare,
                  tooltip: '批量分享',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedSessionIds.isEmpty ? null : _batchDelete,
                  tooltip: '批量删除',
                ),
              ]
            : null,
      ),
      body: Consumer<CheckProvider>(
        builder: (context, provider, child) {
          if (provider.sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    '暂无检查任务',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showCreateDialog,
                    child: const Text('点击创建'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.sessions.length,
            itemBuilder: (context, index) {
              final session = provider.sessions[index];
              return _buildSessionCard(session);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenu,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('新增检查任务'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('导入检查任务'),
                onTap: () {
                  Navigator.pop(context);
                  _importSession();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(CheckSession session) {
    final isSelected = _selectedSessionIds.contains(session.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isMultiSelectMode && isSelected
            ? [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.25),
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
        child: InkWell(
          onTap: () {
            if (_isMultiSelectMode) {
              _toggleSessionSelection(session.id);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CheckDetailScreen(sessionId: session.id),
                ),
              ).then((_) {
                // 从详情页返回时刷新列表（可能修改了完成状态）
                context.read<CheckProvider>().loadSessions();
              });
            }
          },
          onLongPress: () {
            if (!_isMultiSelectMode) {
              _toggleMultiSelectMode();
              _toggleSessionSelection(session.id);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isMultiSelectMode) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _renameSession(session.id, session.name);
                          _exitMultiSelectMode();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    _buildStatusBadge(session.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '创建时间：${_formatTime(session.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (session.status == 0) ...[
                  const SizedBox(height: 8),
                  FutureBuilder<List>(
                    // 每次构建时创建新的 future，确保从详情页返回时能刷新进度
                    future: context
                        .read<CheckProvider>()
                        .getItems(session.id)
                        .then((items) => items),
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? [];
                      final confirmed = items
                          .where((i) => i.isConfirmed)
                          .length;
                      final total = items.length;
                      return Text(
                        '进度：$confirmed / $total',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ], // Column children 结束
            ), // Column
          ), // Padding
        ), // InkWell
      ), // Card
    ); // AnimatedContainer
  }

  Widget _buildStatusBadge(int status) {
    final isCompleted = status == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCompleted ? '已完成' : '进行中',
        style: TextStyle(
          color: isCompleted ? Colors.green.shade700 : Colors.blue.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _batchDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text(
          '确定要删除选中的 ${_selectedSessionIds.length} 个检查任务吗？\n此操作不可恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final provider = context.read<CheckProvider>();
              for (final sessionId in _selectedSessionIds) {
                await provider.deleteSession(sessionId);
              }
              _toggleMultiSelectMode();
              if (mounted) Navigator.pop(context);
              _showSuccess('已删除 ${_selectedSessionIds.length} 个检查任务');
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _batchShare() async {
    try {
      final provider = context.read<CheckProvider>();
      final csvRows = <List<dynamic>>[
        [
          'session_id',
          'session_name',
          'session_status',
          'session_created_at',
          'item_id',
          'asset_id',
          'asset_name',
          'purchase_price',
          'category',
          'asset_status',
          'confirmed_at',
        ],
      ];

      for (final sessionId in _selectedSessionIds) {
        final items = await provider.getItems(sessionId);
        final sessions = provider.sessions;
        final session = sessions.firstWhere((s) => s.id == sessionId);

        for (final item in items) {
          final snapshot = item.snapshotData;
          csvRows.add([
            session.id,
            session.name,
            session.status, // 数字 0 或 1，不是"进行中"
            session.createdAt, // 整数毫秒，不是 ISO
            item.id,
            item.assetId,
            snapshot['assetName'] ?? '',
            snapshot['purchasePrice'] ?? '',
            snapshot['category'] ?? '',
            snapshot['status'] ?? '', // 数字或空，不是"服役中"
            item.confirmedAt ?? '', // 整数毫秒或空，不是 ISO
          ]);
        }
      }

      final csvString = const ListToCsvConverter().convert(csvRows);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultFileName = '检查导出_$timestamp.csv';

      // 使用 BottomSheet 输入文件名
      final nameController = TextEditingController(text: defaultFileName);
      final fileName = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '导出文件名',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '输入文件名',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.pop(ctx, nameController.text.trim()),
                      child: const Text('导出'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      if (fileName == null || fileName.isEmpty) return;

      if (kIsWeb) {
        final bytes = utf8.encode(csvString);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSuccess('已导出 ${_selectedSessionIds.length} 个检查任务');
      } else {
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: '保存检查任务',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['csv'],
          bytes: Uint8List.fromList(utf8.encode(csvString)),
        );

        if (savePath != null && savePath.isNotEmpty) {
          _showSuccess('已保存到：$savePath');
        }
      }

      _toggleMultiSelectMode();
    } catch (e) {
      _showError('导出失败：${e.toString()}');
    }
  }

  void _importSession() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择检查任务文件',
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final fileName = file.name.toLowerCase();

      if (fileName.endsWith('.csv')) {
        await _importFromCsv(file);
      } else {
        await _importFromJson(file);
      }
    } catch (e) {
      _showError('导入失败：${e.toString()}');
    }
  }

  Future<void> _importFromJson(PlatformFile file) async {
    String jsonString;

    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) {
        _showError('无法读取文件内容');
        return;
      }
      jsonString = utf8.decode(bytes);
    } else {
      if (file.path == null) {
        _showError('无法获取文件路径');
        return;
      }
      jsonString = await File(file.path!).readAsString();
    }

    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    // 验证数据格式
    if (!data.containsKey('session') || !data.containsKey('items')) {
      _showError('文件格式不正确');
      return;
    }

    // 导入检查任务
    await context.read<CheckProvider>().importSession(data);

    _showSuccess('导入成功');
  }

  Future<void> _importFromCsv(PlatformFile file) async {
    String csvString;

    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) {
        _showError('无法读取文件内容');
        return;
      }
      csvString = utf8.decode(bytes);
    } else {
      if (file.path == null) {
        _showError('无法获取文件路径');
        return;
      }
      csvString = await File(file.path!).readAsString();
    }

    final csvRows = const CsvToListConverter().convert(csvString);
    if (csvRows.length < 2) {
      _showError('CSV 文件为空或格式不正确');
      return;
    }

    final header = csvRows[0].map((e) => e.toString().toLowerCase()).toList();
    final fieldIndex = <String, int>{};
    for (int i = 0; i < header.length; i++) {
      fieldIndex[header[i]] = i;
    }

    // 必要字段
    for (final field in ['session_id', 'session_name', 'asset_id']) {
      if (!fieldIndex.containsKey(field)) {
        _showError('CSV 缺少必要字段：$field');
        return;
      }
    }

    // 兼容字段名
    final assetStatusKey = fieldIndex.containsKey('asset_status')
        ? 'asset_status'
        : (fieldIndex.containsKey('status') ? 'status' : null);

    // 按 session_id 分组
    final groupedRows = <String, List<List<dynamic>>>{};
    final sessionNames = <String, String>{};

    for (int i = 1; i < csvRows.length; i++) {
      final row = csvRows[i];
      final sid = row[fieldIndex['session_id']!].toString();
      final sname = row[fieldIndex['session_name']!].toString();
      groupedRows.putIfAbsent(sid, () => []).add(row);
      sessionNames[sid] = sname;
    }

    // 每个 session 组创建一个新 session
    int importedCount = 0;
    for (final entry in groupedRows.entries) {
      final rows = entry.value;
      final sessionName = sessionNames[entry.key] ?? '未命名';

      final newSession = await context.read<CheckProvider>().createSession(
        '$sessionName（导入）',
      );

      for (final row in rows) {
        final assetId = row[fieldIndex['asset_id']!].toString();
        final assetName = row[fieldIndex['asset_name']!]?.toString() ?? '';
        final purchasePriceStr =
            row[fieldIndex['purchase_price']!]?.toString() ?? '';
        final category = row[fieldIndex['category']!]?.toString() ?? '';

        final snapshot = <String, dynamic>{
          'id': assetId,
          'assetName': assetName,
          'purchasePrice': double.tryParse(purchasePriceStr),
          'category': category,
        };
        if (assetStatusKey != null) {
          final s = row[fieldIndex[assetStatusKey]!]?.toString() ?? '';
          if (s.isNotEmpty) snapshot['status'] = int.tryParse(s);
        }

        final item = await context.read<CheckProvider>().addItem(
          sessionId: newSession.id,
          assetId: assetId,
          assetSnapshot: jsonEncode(snapshot),
        );

        final confirmedAtStr =
            row[fieldIndex['confirmed_at']!]?.toString() ?? '';
        if (confirmedAtStr.isNotEmpty) {
          final confirmedAtMs = int.tryParse(confirmedAtStr);
          if (confirmedAtMs != null) {
            await context.read<CheckProvider>().confirmItem(item.id);
          }
        }
      }
      importedCount++;
    }

    _showSuccess('导入成功，共 $importedCount 个检查任务');
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
}

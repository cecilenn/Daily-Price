import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
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

  void _confirmDelete(CheckSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除检查任务'),
        content: Text('确定要删除"${session.name}"吗？\n此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CheckProvider>().deleteSession(session.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
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
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAll,
                  tooltip: '全选',
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  if (_isMultiSelectMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        _toggleSessionSelection(session.id);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      session.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                  future: context.read<CheckProvider>().getItems(session.id),
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    final confirmed = items.where((i) => i.isConfirmed).length;
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
            ],
          ),
        ),
      ),
    );
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
      final List<Map<String, dynamic>> exportData = [];

      for (final sessionId in _selectedSessionIds) {
        final data = await provider.exportSession(sessionId);
        exportData.add(data);
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'sessions': exportData,
        'exported_at': DateTime.now().toIso8601String(),
        'app_version': '1.3.2',
      });

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'check_sessions_$timestamp.json';

      if (kIsWeb) {
        final bytes = utf8.encode(jsonString);
        final blob = html.Blob([bytes], 'application/json');
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
          allowedExtensions: ['json'],
          bytes: Uint8List.fromList(utf8.encode(jsonString)),
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

    // 验证必要字段
    final requiredFields = ['session_id', 'session_name', 'asset_id'];
    for (final field in requiredFields) {
      if (!fieldIndex.containsKey(field)) {
        _showError('CSV 缺少必要字段：$field');
        return;
      }
    }

    // 从第一行数据获取 session 信息
    final firstRow = csvRows[1];
    final sessionId = firstRow[fieldIndex['session_id']!].toString();
    final sessionName = firstRow[fieldIndex['session_name']!].toString();
    final sessionStatus =
        int.tryParse(
          firstRow[fieldIndex['session_status']!]?.toString() ?? '0',
        ) ??
        0;
    final createdAt = firstRow[fieldIndex['created_at']!]?.toString() ?? '';

    // 创建新的 session 名称（添加“（导入）”后缀）
    final newSessionName = '$sessionName（导入）';

    // 创建新的 CheckSession
    final newSession = await context.read<CheckProvider>().createSession(
      newSessionName,
    );

    // 遍历每一行，创建 CheckItem
    final items = <Map<String, dynamic>>[];
    for (int i = 1; i < csvRows.length; i++) {
      final row = csvRows[i];
      final assetId = row[fieldIndex['asset_id']!].toString();
      final assetName = row[fieldIndex['asset_name']!]?.toString() ?? '';
      final purchasePrice =
          row[fieldIndex['purchase_price']!]?.toString() ?? '';
      final category = row[fieldIndex['category']!]?.toString() ?? '';
      final status = row[fieldIndex['status']!]?.toString() ?? '';
      final confirmedAt = row[fieldIndex['confirmed_at']!]?.toString() ?? '';

      // 构建 asset_snapshot
      final snapshot = {
        'id': assetId,
        'assetName': assetName,
        'purchasePrice': double.tryParse(purchasePrice),
        'category': category,
        'status': int.tryParse(status),
      };

      items.add({
        'asset_id': assetId,
        'asset_snapshot': jsonEncode(snapshot),
        'confirmed_at': confirmedAt.isNotEmpty ? confirmedAt : null,
      });
    }

    // 导入 items
    for (final item in items) {
      await context.read<CheckProvider>().addItem(
        sessionId: newSession.id,
        assetId: item['asset_id'] as String,
        assetSnapshot: item['asset_snapshot'] as String,
      );
      // 如果有确认时间，则确认该项
      if (item['confirmed_at'] != null) {
        final addedItems = await context.read<CheckProvider>().getItems(
          newSession.id,
        );
        final addedItem = addedItems.firstWhere(
          (e) => e.assetId == item['asset_id'],
        );
        await context.read<CheckProvider>().confirmItem(addedItem.id);
      }
    }

    _showSuccess('导入成功');
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

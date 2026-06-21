import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../providers/check_provider.dart';
import '../services/asset_export_service.dart';
import '../services/check_session_archive_service.dart';
import '../widgets/check_list_widgets.dart';
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
    final rootContext = context;
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final session = await rootContext
                    .read<CheckProvider>()
                    .createSession(name);
                if (mounted && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  await Navigator.push(
                    rootContext,
                    MaterialPageRoute(
                      builder: (_) => CheckDetailScreen(sessionId: session.id),
                    ),
                  );
                  if (!rootContext.mounted) return;
                  rootContext.read<CheckProvider>().loadSessions();
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
            return CheckListEmptyState(onCreatePressed: _showCreateDialog);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.sessions.length,
            itemBuilder: (context, index) {
              final session = provider.sessions[index];
              return CheckSessionCard(
                session: session,
                isSelected: _selectedSessionIds.contains(session.id),
                isMultiSelectMode: _isMultiSelectMode,
                itemFuture: provider.getItems(session.id),
                onTap: () async {
                  if (_isMultiSelectMode) {
                    _toggleSessionSelection(session.id);
                  } else {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CheckDetailScreen(sessionId: session.id),
                      ),
                    );
                    if (!mounted) return;
                    provider.loadSessions();
                  }
                },
                onLongPress: () {
                  if (!_isMultiSelectMode) {
                    _toggleMultiSelectMode();
                    _toggleSessionSelection(session.id);
                  }
                },
                onRenamePressed: () {
                  _renameSession(session.id, session.name);
                  _exitMultiSelectMode();
                },
              );
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
      builder: (context) => CheckAddMenuSheet(
        onCreatePressed: () {
          Navigator.pop(context);
          _showCreateDialog();
        },
        onImportPressed: () {
          Navigator.pop(context);
          _importSession();
        },
      ),
    );
  }

  void _batchDelete() {
    final rootContext = context;
    final selectedCount = _selectedSessionIds.length;
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 $selectedCount 个检查任务吗？\n此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final provider = rootContext.read<CheckProvider>();
              for (final sessionId in _selectedSessionIds) {
                await provider.deleteSession(sessionId);
              }
              if (mounted && dialogContext.mounted) {
                _toggleMultiSelectMode();
                Navigator.pop(dialogContext);
                _showSuccess('已删除 $selectedCount 个检查任务');
              }
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
      final selectedCount = _selectedSessionIds.length;
      final csvString = await CheckSessionArchiveService.exportCsv(
        provider: provider,
        sessionIds: _selectedSessionIds,
      );
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultFileName = '检查导出_$timestamp.csv';

      // 使用 BottomSheet 输入文件名
      final nameController = TextEditingController(text: defaultFileName);
      if (!mounted) return;
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

      if (!mounted) return;
      if (fileName == null || fileName.isEmpty) return;

      final result = await AssetExportService.saveCsv(
        csvString: csvString,
        defaultFileName: fileName,
      );

      if (!mounted || result.isCanceled) return;

      if (result.isUnsupported) {
        _showError(result.errorMessage ?? '当前平台不支持导出');
        return;
      }

      if (result.isSaved) {
        _showSuccess('已导出 $selectedCount 个检查任务：${result.savePath}');
      } else if (result.errorMessage != null) {
        _showError(result.errorMessage!);
        return;
      }

      _toggleMultiSelectMode();
    } catch (e) {
      if (mounted) {
        _showError('导出失败：${e.toString()}');
      }
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

      if (!mounted) return;
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
      if (mounted) {
        _showError('导入失败：${e.toString()}');
      }
    }
  }

  Future<void> _importFromJson(PlatformFile file) async {
    final provider = context.read<CheckProvider>();
    final jsonString = await _readPickedFileAsString(file);
    if (jsonString == null) return;
    if (!mounted) return;

    await CheckSessionArchiveService.importJson(
      provider: provider,
      jsonString: jsonString,
    );
    if (!mounted) return;

    _showSuccess('导入成功');
  }

  Future<void> _importFromCsv(PlatformFile file) async {
    final provider = context.read<CheckProvider>();
    final csvString = await _readPickedFileAsString(file);
    if (csvString == null) return;
    if (!mounted) return;

    final importedCount = await CheckSessionArchiveService.importCsv(
      provider: provider,
      csvString: csvString,
    );
    if (!mounted) return;

    _showSuccess('导入成功，共 $importedCount 个检查任务');
  }

  Future<String?> _readPickedFileAsString(PlatformFile file) async {
    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) {
        _showError('无法读取文件内容');
        return null;
      }
      return utf8.decode(bytes);
    }

    if (file.path == null) {
      _showError('无法获取文件路径');
      return null;
    }
    return File(file.path!).readAsString();
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

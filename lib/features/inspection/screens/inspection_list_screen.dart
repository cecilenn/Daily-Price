import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inspection_provider.dart';
import '../models/company_check_session.dart';
import '../widgets/inspection_list_widgets.dart';
import 'inspection_detail_screen.dart';
import 'webdav_config_screen.dart';
import 'import_session_screen.dart';

class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({super.key});

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  bool _isMultiSelectMode = false;
  final Set<String> _selectedSessionIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspectionProvider>().loadSessions();
    });
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) _selectedSessionIds.clear();
    });
  }

  void _toggleSessionSelection(String id) {
    setState(() {
      if (_selectedSessionIds.contains(id)) {
        _selectedSessionIds.remove(id);
      } else {
        _selectedSessionIds.add(id);
      }
    });
  }

  void _selectAll() {
    final sessions = context.read<InspectionProvider>().sessions;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isMultiSelectMode
            ? Text('已选择 ${_selectedSessionIds.length} 项')
            : const Text('特调检查'),
        centerTitle: true,
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitMultiSelectMode,
              )
            : null,
        actions: [
          if (!_isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.cloud_sync),
              onPressed: _syncAssets,
              tooltip: '同步资产库',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WebdavConfigScreen()),
                );
              },
              tooltip: 'WebDAV 配置',
            ),
          ] else ...[
            Builder(
              builder: (ctx) {
                final provider = ctx.watch<InspectionProvider>();
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
              icon: const Icon(Icons.delete),
              onPressed: _selectedSessionIds.isEmpty ? null : _batchDelete,
              tooltip: '批量删除',
            ),
          ],
        ],
      ),
      body: Consumer<InspectionProvider>(
        builder: (context, provider, child) {
          if (provider.sessions.isEmpty) {
            return InspectionEmptyState(onCreatePressed: _showCreateDialog);
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

  Widget _buildSessionCard(CompanyCheckSession session) {
    final isSelected = _selectedSessionIds.contains(session.id);

    return InspectionSessionCard(
      session: session,
      isMultiSelectMode: _isMultiSelectMode,
      isSelected: isSelected,
      progressFuture: context.read<InspectionProvider>().getItems(session.id),
      onTap: () async {
        if (_isMultiSelectMode) {
          _toggleSessionSelection(session.id);
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InspectionDetailScreen(sessionId: session.id),
          ),
        );
        if (!mounted) return;
        context.read<InspectionProvider>().loadSessions();
      },
      onLongPress: () {
        if (!_isMultiSelectMode) {
          _toggleMultiSelectMode();
          _toggleSessionSelection(session.id);
        }
      },
      onRename: () {
        _renameSession(session.id, session.name);
        _exitMultiSelectMode();
      },
    );
  }

  void _showAddMenu() {
    final rootContext = context;
    showModalBottomSheet(
      context: rootContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return InspectionAddMenu(
          onCreatePressed: () {
            Navigator.pop(sheetContext);
            _showCreateDialog();
          },
          onImportPressed: () async {
            Navigator.pop(sheetContext);
            await Navigator.push(
              rootContext,
              MaterialPageRoute(builder: (_) => const ImportSessionScreen()),
            );
            if (!mounted) return;
            context.read<InspectionProvider>().loadSessions();
          },
        );
      },
    );
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
                    .read<InspectionProvider>()
                    .createSession(name);
                if (rootContext.mounted && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  await Navigator.push(
                    rootContext,
                    MaterialPageRoute(
                      builder: (_) =>
                          InspectionDetailScreen(sessionId: session.id),
                    ),
                  );
                  if (rootContext.mounted) {
                    rootContext.read<InspectionProvider>().loadSessions();
                  }
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
        title: const Text('重命名'),
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
                await context.read<InspectionProvider>().renameSession(
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
              final provider = context.read<InspectionProvider>();
              for (final id in _selectedSessionIds) {
                await provider.deleteSession(id);
              }
              _toggleMultiSelectMode();
              if (context.mounted) Navigator.pop(context);
              _showSuccess('已删除检查任务');
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncAssets() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在同步资产库...'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final count = await context
          .read<InspectionProvider>()
          .syncAssetsFromWebDav();
      if (mounted) {
        _showSuccess('同步成功，共 $count 条资产');
      }
    } catch (e) {
      if (mounted) _showError('同步失败：${e.toString()}');
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
}

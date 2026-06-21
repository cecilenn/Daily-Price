import 'package:flutter/material.dart';

import '../models/check_session.dart';

class CheckListEmptyState extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const CheckListEmptyState({super.key, required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
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
          TextButton(onPressed: onCreatePressed, child: const Text('点击创建')),
        ],
      ),
    );
  }
}

class CheckSessionCard extends StatelessWidget {
  final CheckSession session;
  final bool isSelected;
  final bool isMultiSelectMode;
  final Future<List<CheckItem>> itemFuture;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRenamePressed;

  const CheckSessionCard({
    super.key,
    required this.session,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.itemFuture,
    required this.onTap,
    required this.onLongPress,
    required this.onRenamePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isMultiSelectMode && isSelected
            ? [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isMultiSelectMode && isSelected
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2.5,
              )
            : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
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
                    if (isMultiSelectMode) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onRenamePressed,
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
                    _StatusBadge(status: session.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '创建时间：${_formatDate(session.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (session.status == 0) ...[
                  const SizedBox(height: 8),
                  FutureBuilder<List<CheckItem>>(
                    future: itemFuture,
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? [];
                      final confirmed = items
                          .where((item) => item.isConfirmed)
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CheckAddMenuSheet extends StatelessWidget {
  final VoidCallback onCreatePressed;
  final VoidCallback onImportPressed;

  const CheckAddMenuSheet({
    super.key,
    required this.onCreatePressed,
    required this.onImportPressed,
  });

  @override
  Widget build(BuildContext context) {
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
            onTap: onCreatePressed,
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('导入检查任务'),
            onTap: onImportPressed,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final int status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
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
}

String _formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

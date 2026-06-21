import 'package:flutter/material.dart';

import '../models/company_check_item.dart';
import '../models/company_check_session.dart';

class InspectionEmptyState extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const InspectionEmptyState({super.key, required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade400),
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

class InspectionSessionCard extends StatelessWidget {
  final CompanyCheckSession session;
  final bool isMultiSelectMode;
  final bool isSelected;
  final Future<List<CompanyCheckItem>> progressFuture;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRename;

  const InspectionSessionCard({
    super.key,
    required this.session,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.progressFuture,
    required this.onTap,
    required this.onLongPress,
    required this.onRename,
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
                        onTap: onRename,
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
                  '创建时间：${_formatTime(session.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (session.status == 0) ...[
                  const SizedBox(height: 8),
                  FutureBuilder<List<CompanyCheckItem>>(
                    future: progressFuture,
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? [];
                      final confirmed = items
                          .where((i) => i.isConfirmed)
                          .length;
                      return Text(
                        '进度：$confirmed / ${items.length}',
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

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

class InspectionAddMenu extends StatelessWidget {
  final VoidCallback onCreatePressed;
  final VoidCallback onImportPressed;

  const InspectionAddMenu({
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
            leading: const Icon(Icons.cloud_download),
            title: const Text('从云端导入'),
            onTap: onImportPressed,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

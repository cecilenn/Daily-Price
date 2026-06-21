import 'package:flutter/material.dart';

import '../models/asset.dart';

class ConsumablesSection extends StatelessWidget {
  final bool enabled;
  final List<ConsumableRecord> consumables;
  final List<ReplacementRecord> replacements;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onEditConsumable;
  final ValueChanged<int> onDeleteConsumable;
  final VoidCallback onAddConsumable;
  final ValueChanged<ConsumableRecord> onAddReplacement;
  final void Function(ConsumableRecord consumable, ReplacementRecord record)
  onEditReplacement;
  final ValueChanged<String> onDeleteReplacement;

  const ConsumablesSection({
    super.key,
    required this.enabled,
    required this.consumables,
    required this.replacements,
    required this.onEnabledChanged,
    required this.onEditConsumable,
    required this.onDeleteConsumable,
    required this.onAddConsumable,
    required this.onAddReplacement,
    required this.onEditReplacement,
    required this.onDeleteReplacement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('耗材追踪'),
          subtitle: Text(enabled ? '${consumables.length} 个耗材' : '关闭'),
          secondary: const Icon(Icons.inventory_2_outlined),
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        if (enabled) ...[
          const SizedBox(height: 8),
          ...consumables.asMap().entries.map((entry) {
            final index = entry.key;
            final consumable = entry.value;
            final records =
                replacements
                    .where((r) => r.consumableName == consumable.name)
                    .toList()
                  ..sort((a, b) => b.replacedAt.compareTo(a.replacedAt));

            return _ConsumableCard(
              consumable: consumable,
              records: records,
              onEditConsumable: () => onEditConsumable(index),
              onDeleteConsumable: () => onDeleteConsumable(index),
              onAddReplacement: () => onAddReplacement(consumable),
              onEditReplacement: (record) =>
                  onEditReplacement(consumable, record),
              onDeleteReplacement: onDeleteReplacement,
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加耗材'),
              onPressed: onAddConsumable,
            ),
          ),
        ],
      ],
    );
  }
}

class _ConsumableCard extends StatelessWidget {
  final ConsumableRecord consumable;
  final List<ReplacementRecord> records;
  final VoidCallback onEditConsumable;
  final VoidCallback onDeleteConsumable;
  final VoidCallback onAddReplacement;
  final ValueChanged<ReplacementRecord> onEditReplacement;
  final ValueChanged<String> onDeleteReplacement;

  const _ConsumableCard({
    required this.consumable,
    required this.records,
    required this.onEditConsumable,
    required this.onDeleteConsumable,
    required this.onAddReplacement,
    required this.onEditReplacement,
    required this.onDeleteReplacement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(consumable.name),
        subtitle: Text(
          consumable.price > 0
              ? '¥${consumable.price.toStringAsFixed(0)} / ${consumable.cycleDays}天 · 日均¥${consumable.dailyCost.toStringAsFixed(1)}'
              : '${consumable.cycleDays}天',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEditConsumable,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              onPressed: onDeleteConsumable,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '购买日期：${_formatDate(consumable.purchasedAt)}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '暂无更换记录',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            ...records.map(
              (record) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 32, right: 8),
                leading: const Icon(Icons.history, size: 18),
                title: Text(
                  _formatDate(record.replacedAt),
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  '¥${record.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () => onEditReplacement(record),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      onPressed: () => onDeleteReplacement(record.id),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加更换记录', style: TextStyle(fontSize: 13)),
                onPressed: onAddReplacement,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';

import '../models/asset.dart';

class AssetConsumablesCard extends StatelessWidget {
  final Asset asset;
  final ValueChanged<ConsumableRecord> onConsumableTap;

  const AssetConsumablesCard({
    super.key,
    required this.asset,
    required this.onConsumableTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '耗材管理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...asset.consumables.map(
              (consumable) => _ConsumableListTile(
                asset: asset,
                consumable: consumable,
                onTap: () => onConsumableTap(consumable),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssetConsumableDetailSheet extends StatelessWidget {
  final Asset asset;
  final ConsumableRecord consumable;
  final Future<void> Function() onMarkReplaced;
  final Future<void> Function(ReplacementRecord record) onDeleteReplacement;

  const AssetConsumableDetailSheet({
    super.key,
    required this.asset,
    required this.consumable,
    required this.onMarkReplaced,
    required this.onDeleteReplacement,
  });

  @override
  Widget build(BuildContext context) {
    final records =
        asset.replacements
            .where((record) => record.consumableName == consumable.name)
            .toList()
          ..sort((a, b) => b.replacedAt.compareTo(a.replacedAt));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            consumable.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '单价: ¥${consumable.price.toStringAsFixed(0)} · 周期: ${consumable.cycleDays}天',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.build),
              label: const Text('标记已更换'),
              onPressed: onMarkReplaced,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '更换记录',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (records.isEmpty)
            const Text('暂无更换记录', style: TextStyle(color: Colors.grey))
          else
            ...records.map(
              (record) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(_formatDate(record.replacedAt)),
                subtitle: Text(
                  '¥${record.price.toStringAsFixed(0)}${record.note?.isNotEmpty == true ? " · ${record.note}" : ""}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => onDeleteReplacement(record),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConsumableListTile extends StatelessWidget {
  final Asset asset;
  final ConsumableRecord consumable;
  final VoidCallback onTap;

  const _ConsumableListTile({
    required this.asset,
    required this.consumable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = asset.getConsumableRemainingDays(consumable);
    final isExpired = remaining < 0;
    final isUrgent = remaining >= 0 && remaining <= 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isExpired ? Icons.warning : Icons.schedule,
          color: isExpired
              ? Colors.red
              : (isUrgent ? Colors.orange : Colors.green),
        ),
        title: Text(consumable.name),
        subtitle: Text(
          '周期: ${consumable.cycleDays}天 · 单价: ¥${consumable.price.toStringAsFixed(0)}',
        ),
        trailing: Text(
          isExpired ? '已过期${-remaining}天' : '剩余$remaining天',
          style: TextStyle(
            color: isExpired
                ? Colors.red
                : (isUrgent ? Colors.orange : Colors.grey),
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

String _formatDate(int? timestamp) {
  if (timestamp == null) return '-';
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

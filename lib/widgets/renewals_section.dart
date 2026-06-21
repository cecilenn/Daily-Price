import 'package:flutter/material.dart';

import '../models/asset.dart';

class RenewalsSection extends StatelessWidget {
  final List<RenewalRecord> renewals;
  final VoidCallback onAddRenewal;
  final ValueChanged<String> onDeleteRenewal;

  const RenewalsSection({
    super.key,
    required this.renewals,
    required this.onAddRenewal,
    required this.onDeleteRenewal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '续费记录（${renewals.length} 条）',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加续费'),
              onPressed: onAddRenewal,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (renewals.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('暂无续费记录', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...renewals.map(
            (renewal) => _RenewalCard(
              renewal: renewal,
              onDelete: () => onDeleteRenewal(renewal.id),
            ),
          ),
      ],
    );
  }
}

class _RenewalCard extends StatelessWidget {
  final RenewalRecord renewal;
  final VoidCallback onDelete;

  const _RenewalCard({required this.renewal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(renewal.renewalDate);
    final expireStr = _formatDate(renewal.expireDate);
    final durationText = _formatDuration(renewal.durationDays);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '$dateStr  ¥${renewal.price.toStringAsFixed(0)}/$durationText',
        ),
        subtitle: Text('到期：$expireStr'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }

  static String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatDuration(int days) {
    if (days >= 365) {
      return '${(days / 365).toStringAsFixed(1)}年';
    }
    if (days >= 30) {
      return '${(days / 30).round()}月';
    }
    return '$days天';
  }
}

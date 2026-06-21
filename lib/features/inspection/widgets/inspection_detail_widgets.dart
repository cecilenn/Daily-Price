import 'package:flutter/material.dart';

import '../models/company_check_item.dart';

class InspectionProgressHeader extends StatelessWidget {
  final List<CompanyCheckItem> items;

  const InspectionProgressHeader({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final confirmed = items.where((i) => i.isConfirmed).length;
    final total = items.length;
    final progress = total > 0 ? confirmed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '检查进度',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                '$confirmed / $total',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class InspectionFilterBar extends StatelessWidget {
  final int filter;
  final ValueChanged<int> onFilterChanged;

  const InspectionFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('全部'),
            selected: filter == 0,
            onSelected: (selected) {
              if (selected) onFilterChanged(0);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('已确认'),
            selected: filter == 1,
            onSelected: (selected) {
              if (selected) onFilterChanged(1);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('未确认'),
            selected: filter == 2,
            onSelected: (selected) {
              if (selected) onFilterChanged(2);
            },
          ),
        ],
      ),
    );
  }
}

class InspectionCheckItemCard extends StatelessWidget {
  final CompanyCheckItem item;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const InspectionCheckItemCard({
    super.key,
    required this.item,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
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
        child: ListTile(
          leading: Icon(
            item.isConfirmed ? Icons.check_circle : Icons.circle_outlined,
            color: item.isConfirmed ? Colors.green : Colors.red,
          ),
          title: Text(item.assetName),
          subtitle: Text(
            '资产编码: ${item.assetCode}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      ),
    );
  }
}

class InspectionMultiSelectBottomSheet extends StatelessWidget {
  final bool hasSelection;
  final VoidCallback? onConfirm;
  final VoidCallback? onUnconfirm;

  const InspectionMultiSelectBottomSheet({
    super.key,
    required this.hasSelection,
    required this.onConfirm,
    required this.onUnconfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.check_circle,
              label: '标记已确认',
              color: Colors.green,
              onPressed: hasSelection ? onConfirm : null,
            ),
            _ActionButton(
              icon: Icons.remove_circle_outline,
              label: '取消确认',
              color: Colors.orange,
              onPressed: hasSelection ? onUnconfirm : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

class InspectionAssetDetailSheet extends StatelessWidget {
  final CompanyCheckItem item;
  final ScrollController scrollController;
  final VoidCallback onClose;

  const InspectionAssetDetailSheet({
    super.key,
    required this.item,
    required this.scrollController,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final snapshot = item.snapshotData;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.assetName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            item.isConfirmed
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 16,
                            color: item.isConfirmed ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.isConfirmed ? '已确认' : '未确认',
                            style: TextStyle(
                              fontSize: 14,
                              color: item.isConfirmed
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetailItem(label: '资产编码', value: item.assetCode),
                  if (_hasValue(snapshot['spec']))
                    DetailItem(label: '规格型号', value: snapshot['spec']),
                  if (_hasValue(snapshot['department']))
                    DetailItem(label: '使用部门', value: snapshot['department']),
                  if (_hasValue(snapshot['user']))
                    DetailItem(label: '使用人', value: snapshot['user']),
                  if (_hasValue(snapshot['location']))
                    DetailItem(label: '存放位置', value: snapshot['location']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValue(Object? value) => value != null && value.toString().isNotEmpty;
}

class DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const DetailItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/check_session.dart';

class CheckProgressHeader extends StatelessWidget {
  final List<CheckItem> items;

  const CheckProgressHeader({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final confirmed = items.where((item) => item.isConfirmed).length;
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

class CheckFilterBar extends StatelessWidget {
  final int filter;
  final ValueChanged<int> onFilterChanged;

  const CheckFilterBar({
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
          _filterChip('全部', 0),
          const SizedBox(width: 8),
          _filterChip('已确认', 1),
          const SizedBox(width: 8),
          _filterChip('未确认', 2),
        ],
      ),
    );
  }

  ChoiceChip _filterChip(String label, int value) {
    return ChoiceChip(
      label: Text(label),
      selected: filter == value,
      onSelected: (selected) {
        if (selected) {
          onFilterChanged(value);
        }
      },
    );
  }
}

class CheckItemCard extends StatelessWidget {
  final CheckItem item;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CheckItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isMultiSelectMode,
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
            '资产ID: ${item.assetId}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      ),
    );
  }
}

class CheckMultiSelectActionSheet extends StatelessWidget {
  final bool hasSelection;
  final VoidCallback onConfirm;
  final VoidCallback onUnconfirm;

  const CheckMultiSelectActionSheet({
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

class CheckAssetDetailSheet extends StatelessWidget {
  final CheckItem item;
  final ScrollController scrollController;

  const CheckAssetDetailSheet({
    super.key,
    required this.item,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
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
                Expanded(child: _AssetDetailTitle(item: item)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: _AssetDetailContent(snapshotData: item.snapshotData),
            ),
          ),
        ],
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

class _AssetDetailTitle extends StatelessWidget {
  final CheckItem item;

  const _AssetDetailTitle({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.assetName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              item.isConfirmed ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: item.isConfirmed ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              item.isConfirmed ? '已确认' : '未确认',
              style: TextStyle(
                fontSize: 14,
                color: item.isConfirmed ? Colors.green : Colors.red,
              ),
            ),
            if (item.isConfirmed && item.confirmedAt != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatDateTime(item.confirmedAt!),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _AssetDetailContent extends StatelessWidget {
  final Map<String, dynamic> snapshotData;

  const _AssetDetailContent({required this.snapshotData});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (snapshotData.containsKey('purchasePrice') &&
        snapshotData['purchasePrice'] != null) {
      items.add(_DetailItem('购入价格', '¥${snapshotData['purchasePrice']}'));
    }

    if (snapshotData.containsKey('purchaseDate') &&
        snapshotData['purchaseDate'] != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        snapshotData['purchaseDate'] as int,
      );
      items.add(_DetailItem('购买日期', _formatDate(date)));
    }

    if (snapshotData.containsKey('category') &&
        snapshotData['category'] != null) {
      items.add(_DetailItem('分类', snapshotData['category'].toString()));
    }

    if (snapshotData.containsKey('status') && snapshotData['status'] != null) {
      items.add(_DetailItem('状态', _assetStatusText(snapshotData['status'])));
    }

    if (snapshotData.containsKey('expectedLifespanDays') &&
        snapshotData['expectedLifespanDays'] != null) {
      items.add(
        _DetailItem('预期寿命', '${snapshotData['expectedLifespanDays']} 天'),
      );
    }

    if (snapshotData.containsKey('soldPrice') &&
        snapshotData['soldPrice'] != null) {
      items.add(_DetailItem('卖出价格', '¥${snapshotData['soldPrice']}'));
    }

    if (snapshotData.containsKey('tags') && snapshotData['tags'] != null) {
      final tags = snapshotData['tags'];
      if (tags is List && tags.isNotEmpty) {
        items.add(_DetailItem('标签', tags.join(', ')));
      }
    }

    if (items.isEmpty) {
      return const Center(
        child: Text('暂无详细信息', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

String _assetStatusText(dynamic status) {
  return status == 0
      ? '服役中'
      : status == 1
      ? '已退役'
      : '已卖出';
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatDateTime(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

import 'package:flutter/material.dart';

import '../models/asset.dart';
import 'smart_asset_avatar.dart';

class HomeAssetCard extends StatelessWidget {
  final Asset asset;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?> onSelectedChanged;

  const HomeAssetCard({
    super.key,
    required this.asset,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(asset.status);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: isMultiSelectMode && isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
          : (asset.status == 1 || asset.status == 2)
          ? Colors.grey.shade200
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isMultiSelectMode)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: onSelectedChanged,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                        else
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (asset.isPinned == 1)
                          Icon(
                            Icons.push_pin,
                            size: 12,
                            color: Colors.orange.shade600,
                          )
                        else
                          const SizedBox(width: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SmartAssetAvatar(asset: asset, radius: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    asset.assetName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: (asset.status == 1 || asset.status == 2)
                          ? TextDecoration.lineThrough
                          : null,
                      color: (asset.status == 1 || asset.status == 2)
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  _AssetCostSummary(asset: asset),
                ],
              ),
            ),
            if (asset.status == 1)
              const _RetiredStamp()
            else if (asset.status == 2)
              const _SoldStamp(),
          ],
        ),
      ),
    );
  }

  static Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.red.shade400;
      default:
        return Colors.blue;
    }
  }
}

class _AssetCostSummary extends StatelessWidget {
  final Asset asset;

  const _AssetCostSummary({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '日均: ${_formatCurrency(asset.dailyCost)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '买入: ${_formatCurrency(asset.purchasePrice)}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (asset.hasConsumables) ...[
          const SizedBox(height: 2),
          ...asset.consumables.map((consumable) {
            final remaining = asset.getConsumableRemainingDays(consumable);
            final isExpired = remaining < 0;
            return Text(
              isExpired
                  ? '${consumable.name} ${-remaining}天前'
                  : '${consumable.name} $remaining天',
              style: TextStyle(
                fontSize: 10,
                color: isExpired ? Colors.red : Colors.grey.shade400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            );
          }),
        ],
      ],
    );
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return '-';
    return '¥${amount.toStringAsFixed(2)}';
  }
}

class _RetiredStamp extends StatelessWidget {
  const _RetiredStamp();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100.withValues(alpha: 0.3),
        ),
        child: Center(
          child: Transform.rotate(
            angle: -0.4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87, width: 1.2),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white.withValues(alpha: 0.9),
              ),
              child: Text(
                '已退役',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoldStamp extends StatelessWidget {
  const _SoldStamp();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100.withValues(alpha: 0.3),
        ),
        child: Center(
          child: Transform.rotate(
            angle: -0.4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade300, width: 1.2),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white.withValues(alpha: 0.9),
              ),
              child: Text(
                '已卖出',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

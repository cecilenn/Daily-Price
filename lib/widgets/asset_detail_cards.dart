import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/asset.dart';
import '../utils/time_formatter.dart';
import 'smart_asset_avatar.dart';

class AssetDetailHeaderImage extends StatelessWidget {
  final Asset asset;

  const AssetDetailHeaderImage({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey.shade200,
      child: Center(
        child: SmartAssetAvatar(
          asset: asset,
          radius: 80,
          defaultBgColor: const Color(0xFFE0E0E0),
        ),
      ),
    );
  }
}

class AssetBasicInfoCard extends StatelessWidget {
  final Asset asset;

  const AssetBasicInfoCard({super.key, required this.asset});

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
            const _CardTitle('基本信息'),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.inventory_2,
              label: '资产名称',
              value: asset.assetName,
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.attach_money,
              label: '购入价格',
              value: '¥${(asset.purchasePrice ?? 0).toStringAsFixed(2)}',
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.trending_up,
              label: '当前日均',
              value: '¥${asset.dailyCost.toStringAsFixed(2)}',
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.category,
              label: '资产分类',
              value: asset.category,
            ),
          ],
        ),
      ),
    );
  }
}

class AssetStatusInfoCard extends StatelessWidget {
  final Asset asset;

  const AssetStatusInfoCard({super.key, required this.asset});

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
            const _CardTitle('状态信息'),
            const SizedBox(height: 16),
            _StatusRow(
              icon: Icons.check_circle,
              label: '资产状态',
              value: _statusName(asset.status),
              valueColor: _statusColor(asset.status),
            ),
            if (asset.isSubscription) ...[
              const Divider(height: 24),
              _DetailRow(
                icon: Icons.event_available,
                label: '当前到期日',
                value: asset.currentExpireDate != null
                    ? _formatTimestamp(asset.currentExpireDate)
                    : '未设置',
              ),
              const Divider(height: 24),
              _DetailRow(
                icon: Icons.timer,
                label: '剩余天数',
                value: asset.currentExpireDate != null
                    ? '${asset.subscriptionRemainingDays} 天'
                    : '未设置',
              ),
              const Divider(height: 24),
              _DetailRow(
                icon: Icons.attach_money,
                label: '总续费金额',
                value: '¥${asset.totalRenewalCost.toStringAsFixed(2)}',
              ),
              const Divider(height: 24),
              _DetailRow(
                icon: Icons.history,
                label: '续费记录',
                value: '${asset.renewals.length} 条',
              ),
            ] else ...[
              const Divider(height: 24),
              FutureBuilder<String>(
                future: _formattedDays(asset.expectedLifespanDays),
                builder: (context, snapshot) {
                  return _DetailRow(
                    icon: Icons.timelapse,
                    label: '预计使用',
                    value:
                        snapshot.data ??
                        (asset.expectedLifespanDays != null
                            ? '${asset.expectedLifespanDays} 天'
                            : '未设置'),
                  );
                },
              ),
            ],
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.event,
              label: '购买日期',
              value: _formatTimestamp(asset.purchaseDate),
            ),
            if (asset.status == 1 || asset.status == 2) ...[
              const Divider(height: 24),
              _DetailRow(
                icon: Icons.event_available,
                label: asset.status == 2 ? '卖出日期' : '退役日期',
                value: _formatTimestamp(asset.soldDate),
              ),
            ],
            if (asset.status == 2 && asset.soldPrice != null) ...[
              const Divider(height: 24),
              _DetailRow(
                icon: Icons.sell,
                label: '卖出价格',
                value: '¥${asset.soldPrice!.toStringAsFixed(2)}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AssetExtraInfoCard extends StatelessWidget {
  final Asset asset;

  const AssetExtraInfoCard({super.key, required this.asset});

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
            const _CardTitle('其他信息'),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.push_pin,
              label: '置顶状态',
              value: asset.isPinned == 1 ? '已置顶' : '未置顶',
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.account_balance_wallet,
              label: '不计入总资产',
              value: asset.excludeFromTotal == 1 ? '是' : '否',
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.trending_down,
              label: '不计入日均',
              value: asset.excludeFromDaily == 1 ? '是' : '否',
            ),
            if (asset.tags.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                '标签',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: asset.tags.map((tag) {
                  final displayTag = tag.startsWith('custom_')
                      ? tag.substring(7)
                      : tag;
                  return Chip(
                    label: Text(displayTag),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;

  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

String _statusName(int status) {
  switch (status) {
    case 0:
      return '服役中';
    case 1:
      return '已退役';
    case 2:
      return '已卖出';
    default:
      return '未知';
  }
}

Color _statusColor(int status) {
  switch (status) {
    case 0:
      return Colors.green;
    case 1:
      return Colors.grey;
    case 2:
      return Colors.purple;
    default:
      return Colors.black87;
  }
}

String _formatTimestamp(int? timestamp) {
  if (timestamp == null) return '-';
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Future<String> _formattedDays(int? days) async {
  if (days == null) return Future.value('');
  final prefs = await SharedPreferences.getInstance();
  final mode = prefs.getString('time_display_mode') ?? 'auto';
  return TimeFormatter.formatDays(days, mode: mode);
}

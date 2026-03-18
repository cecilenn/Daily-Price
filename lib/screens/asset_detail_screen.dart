import 'package:flutter/material.dart';
import '../models/asset.dart';
import 'qr_code_screen.dart';

/// ==================== 资产详情页面 ====================
/// 展示资产完整信息，支持编辑和查看二维码
class AssetDetailScreen extends StatelessWidget {
  final Asset asset;

  const AssetDetailScreen({
    super.key,
    required this.asset,
  });

  /// 格式化金额
  String _formatCurrency(double amount) {
    return '¥${amount.toStringAsFixed(2)}';
  }

  /// 格式化天数
  String _formatDays(int days) {
    if (days <= 0) return '0 天';
    final years = days ~/ 365;
    final remainingAfterYears = days % 365;
    final months = remainingAfterYears ~/ 30;
    final remainingDays = remainingAfterYears % 30;

    final parts = <String>[];
    if (years > 0) parts.add('$years 年');
    if (months > 0) parts.add('$months 月');
    if (remainingDays > 0) parts.add('$remainingDays 天');

    return parts.isEmpty ? '0 天' : parts.join('');
  }

  /// 获取分类显示名称
  String _getCategoryLabel(String value) {
    switch (value) {
      case 'physical':
        return '实体资产';
      case 'virtual':
        return '虚拟资产';
      case 'subscription':
        return '限时资产';
      default:
        return '其他';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资产详情'),
        centerTitle: true,
        actions: [
          // 二维码按钮
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QrCodeScreen(asset: asset),
                ),
              );
            },
            tooltip: '查看二维码',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 资产名称卡片
                _buildHeaderCard(),
                const SizedBox(height: 16),
                // 基本信息
                _buildSectionTitle('基本信息'),
                _buildInfoCard([
                  _buildInfoRow('资产名称', asset.assetName),
                  _buildInfoRow('资产分类', _getCategoryLabel(asset.category)),
                  _buildInfoRow('购入价格', _formatCurrency(asset.purchasePrice)),
                  _buildInfoRow('预计使用', _formatDays(asset.expectedLifespanDays)),
                  _buildInfoRow('购买日期', _formatDate(asset.purchaseDate)),
                  if (asset.expireDate != null)
                    _buildInfoRow('到期日期', _formatDate(asset.expireDate!), isWarning: asset.expireDate!.isBefore(DateTime.now())),
                ]),
                const SizedBox(height: 16),
                // 价值计算
                _buildSectionTitle('价值计算'),
                _buildInfoCard([
                  _buildInfoRow('日均成本', _formatCurrency(asset.dailyCost), valueColor: Colors.blue),
                  _buildInfoRow('剩余价值', _formatCurrency(asset.remainingValue), valueColor: Colors.green),
                  _buildInfoRow('已折旧', _formatCurrency(asset.depreciatedValue), valueColor: Colors.orange),
                  _buildInfoRow('已使用', _formatDays(asset.usedDays)),
                  _buildInfoRow('剩余天数', '${asset.remainingDays} 天', valueColor: asset.remainingDays == 0 ? Colors.red : null),
                ]),
                const SizedBox(height: 16),
                // 出售信息（如果已出售）
                if (asset.isSold) ...[
                  _buildSectionTitle('出售信息'),
                  _buildInfoCard([
                    _buildInfoRow('出售价格', _formatCurrency(asset.soldPrice ?? 0), valueColor: Colors.green),
                    if (asset.soldDate != null)
                      _buildInfoRow('出售日期', _formatDate(asset.soldDate!)),
                    _buildInfoRow('实际使用', _formatDays(asset.actualUsedDays)),
                    _buildInfoRow('实际日均', _formatCurrency(asset.actualDailyCost), valueColor: Colors.purple),
                    _buildInfoRow('盈亏', _formatCurrency(asset.soldProfitOrLoss.abs()),
                      valueColor: asset.soldProfitOrLoss >= 0 ? Colors.green : Colors.red,
                      prefix: asset.soldProfitOrLoss >= 0 ? '+' : '-',
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],
                // 标签
                if (asset.tags.isNotEmpty) ...[
                  _buildSectionTitle('标签'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: asset.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: Colors.blue.shade50,
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                // 元信息
                _buildSectionTitle('元信息'),
                _buildInfoCard([
                  _buildInfoRow('资产 ID', asset.id ?? '未分配', isMono: true),
                  _buildInfoRow('创建时间', _formatDateTime(asset.createdAt)),
                  if (asset.userId != null)
                    _buildInfoRow('用户 ID', asset.userId!, isMono: true),
                ]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建头部卡片
  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getCategoryColor(asset.category),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(asset.category),
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.assetName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getCategoryLabel(asset.category),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (asset.isSold)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '已出售',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// 构建信息卡片
  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isWarning = false,
    bool isMono = false,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Row(
            children: [
              if (prefix != null)
                Text(
                  prefix,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isWarning ? Colors.red : (valueColor ?? Colors.black87),
                  fontFamily: isMono ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 获取分类颜色
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'physical':
        return Colors.blue;
      case 'virtual':
        return Colors.purple;
      case 'subscription':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// 获取分类图标
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'physical':
        return Icons.devices;
      case 'virtual':
        return Icons.cloud;
      case 'subscription':
        return Icons.subscriptions;
      default:
        return Icons.category;
    }
  }
}

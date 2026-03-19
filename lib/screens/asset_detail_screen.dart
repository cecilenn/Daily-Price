import 'dart:io';
import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/local_db_service.dart';
import 'add_edit_asset_screen.dart';

/// 资产详情页面 - V2.0 新增
class AssetDetailScreen extends StatefulWidget {
  final Asset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  late Asset _currentAsset;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.asset;
  }

  /// 编辑资产 - V2.0 使用全屏页面
  Future<void> _editAsset() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAssetScreen(existingAsset: _currentAsset),
      ),
    );

    // 如果编辑成功，刷新当前页面数据
    if (result == true && mounted) {
      setState(() => _isRefreshing = true);
      try {
        // 从数据库重新加载最新数据
        final assets = await LocalDbService().getAllAssets();
        final updatedAsset = assets.firstWhere(
          (a) => a.id == _currentAsset.id,
          orElse: () => _currentAsset,
        );
        if (mounted) {
          setState(() {
            _currentAsset = updatedAsset;
            _isRefreshing = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = _currentAsset;

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.assetName),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editAsset,
            tooltip: '编辑',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 顶部大图头像
            _buildHeaderImage(asset),
            const SizedBox(height: 16),
            // 详情信息卡片
            _buildDetailCard(asset),
            const SizedBox(height: 8),
            // 状态信息卡片
            _buildStatusCard(asset),
            const SizedBox(height: 8),
            // 其他信息卡片
            _buildInfoCard(asset),
          ],
        ),
      ),
    );
  }

  /// 构建顶部大图头像
  Widget _buildHeaderImage(Asset asset) {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey.shade200,
      child: asset.avatarPath != null && File(asset.avatarPath!).existsSync()
          ? Image.file(File(asset.avatarPath!), fit: BoxFit.cover)
          : _buildTextAvatar(asset.assetName),
    );
  }

  /// 构建文字头像（无图时显示首字母）
  Widget _buildTextAvatar(String name) {
    final firstChar = name.isNotEmpty ? name[0].toUpperCase() : '?';
    // 根据名称生成固定颜色
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    final color = colors[name.hashCode % colors.length];

    return Container(
      color: color.withOpacity(0.1),
      child: Center(
        child: Text(
          firstChar,
          style: TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  /// 构建详情信息卡片
  Widget _buildDetailCard(Asset asset) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '基本信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.inventory_2,
              label: '资产名称',
              value: asset.assetName,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.attach_money,
              label: '购入价格',
              value: '¥${(asset.purchasePrice ?? 0).toStringAsFixed(2)}',
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.trending_up,
              label: '当前日均',
              value: '¥${asset.dailyCost.toStringAsFixed(2)}',
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.category,
              label: '资产分类',
              value: _getCategoryName(asset.category),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建状态信息卡片
  Widget _buildStatusCard(Asset asset) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '状态信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              icon: Icons.check_circle,
              label: '资产状态',
              value: _getStatusName(asset.status),
              valueColor: _getStatusColor(asset.status),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.timelapse,
              label: '预计使用',
              value: asset.expectedLifespanDays != null
                  ? '${asset.expectedLifespanDays} 天'
                  : '未设置',
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.event,
              label: '购买日期',
              value: _formatTimestamp(asset.purchaseDate),
            ),
            if (asset.status == 1 || asset.status == 2) ...[
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.event_available,
                label: asset.status == 2 ? '卖出日期' : '退役日期',
                value: _formatTimestamp(asset.soldDate),
              ),
            ],
            if (asset.status == 2 && asset.soldPrice != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
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

  /// 构建其他信息卡片
  Widget _buildInfoCard(Asset asset) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '其他信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.push_pin,
              label: '置顶状态',
              value: asset.isPinned == 1 ? '已置顶' : '未置顶',
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.account_balance_wallet,
              label: '不计入总资产',
              value: asset.excludeFromTotal == 1 ? '是' : '否',
            ),
            const Divider(height: 24),
            _buildDetailRow(
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

  /// 构建详情行
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
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

  /// 构建状态行
  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
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

  /// 获取分类名称
  String _getCategoryName(String category) {
    switch (category) {
      case 'physical':
        return '实体资产';
      case 'virtual':
        return '虚拟资产';
      case 'subscription':
        return '限时资产';
      default:
        return category;
    }
  }

  /// 获取状态名称
  String _getStatusName(int status) {
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

  /// 获取状态颜色
  Color _getStatusColor(int status) {
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

  /// 格式化时间戳
  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return '-';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

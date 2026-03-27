import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../utils/time_formatter.dart';
import '../widgets/smart_asset_avatar.dart';
import 'add_edit_asset_screen.dart';

/// 资产详情页面 - V2.0 新增
/// V2.1: 新增 isPreview 预览模式
class AssetDetailScreen extends StatefulWidget {
  final Asset asset;
  final bool isPreview;

  const AssetDetailScreen({
    super.key,
    required this.asset,
    this.isPreview = false,
  });

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

    // 如果编辑成功，从 Provider 获取最新数据
    if (result == true && mounted) {
      // Provider 已经更新了数据，直接从 Provider 取最新
      final updatedAsset = context.read<AssetProvider>().assets.firstWhere(
        (a) => a.id == _currentAsset.id,
        orElse: () => _currentAsset,
      );
      setState(() {
        _currentAsset = updatedAsset;
      });
      // 通知主页刷新（虽然 Provider 已自动通知，保留 pop(true) 兼容现有导航逻辑）
      Navigator.pop(context, true);
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
          // V2.1: 预览模式下隐藏编辑和分享按钮
          if (!widget.isPreview) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _handleShareAsset(),
              tooltip: '分享',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editAsset,
              tooltip: '编辑',
            ),
          ],
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
            const SizedBox(height: 8),
            // 耗材管理区域
            if (asset.hasConsumables) ...[
              _buildConsumablesCard(asset),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            // V2.1: 底部删除按钮
            _buildDeleteButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// V2.1: 构建底部操作按钮（普通模式显示删除，预览模式显示入库）
  Widget _buildDeleteButton() {
    // 预览模式：显示「加入我的库存」按钮
    if (widget.isPreview) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleAddToInventory(),
              icon: const Icon(Icons.add_circle, color: Colors.white),
              label: const Text(
                '加入我的库存',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),
      );
    }

    // 普通模式：显示删除按钮
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleDeleteAsset(),
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text(
              '彻底删除此资产',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }

  /// V2.1: 预览模式 - 将资产加入库存
  Future<void> _handleAddToInventory() async {
    try {
      // 通过 Provider 保存资产
      await context.read<AssetProvider>().saveAsset(_currentAsset);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已成功加入库存'),
            backgroundColor: Colors.green,
          ),
        );
        // 返回 true 通知主页刷新列表
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入库存失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 构建顶部大图头像 - V3.0 使用 SmartAssetAvatar
  Widget _buildHeaderImage(Asset asset) {
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
            // 订阅资产：显示续费相关信息
            if (asset.isSubscription) ...[
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.event_available,
                label: '当前到期日',
                value: asset.currentExpireDate != null
                    ? _formatTimestamp(asset.currentExpireDate)
                    : '未设置',
              ),
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.timer,
                label: '剩余天数',
                value: asset.renewals.isNotEmpty
                    ? '${asset.subscriptionRemainingDays} 天'
                    : '无续费记录',
              ),
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.attach_money,
                label: '总续费金额',
                value: '¥${asset.totalRenewalCost.toStringAsFixed(2)}',
              ),
              const Divider(height: 24),
              _buildDetailRow(
                icon: Icons.history,
                label: '续费记录',
                value: '${asset.renewals.length} 条',
              ),
            ] else ...[
              // 买断资产：显示预计使用天数
              const Divider(height: 24),
              FutureBuilder<String>(
                future: _getFormattedDays(asset.expectedLifespanDays),
                builder: (context, snapshot) {
                  return _buildDetailRow(
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

  /// 构建耗材管理卡片
  Widget _buildConsumablesCard(Asset asset) {
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
            ...asset.consumables.map((c) {
              final remaining = asset.getConsumableRemainingDays(c);
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
                  title: Text(c.name),
                  subtitle: Text(
                    '周期: ${c.cycleDays}天 · 单价: ¥${c.price.toStringAsFixed(0)}',
                  ),
                  trailing: Text(
                    isExpired ? '已过期${-remaining}天' : '剩余${remaining}天',
                    style: TextStyle(
                      color: isExpired
                          ? Colors.red
                          : (isUrgent ? Colors.orange : Colors.grey),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _showConsumableDetail(c),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 显示耗材详情
  void _showConsumableDetail(ConsumableRecord consumable) {
    // 获取该耗材的所有更换记录
    final records =
        _currentAsset.replacements
            .where((r) => r.consumableName == consumable.name)
            .toList()
          ..sort((a, b) => b.replacedAt.compareTo(a.replacedAt)); // 最新的在前

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 拖拽手柄
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
                // 耗材信息
                Text(
                  consumable.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '单价: ¥${consumable.price.toStringAsFixed(0)} · 周期: ${consumable.cycleDays}天',
                ),
                const SizedBox(height: 16),
                // 标记更换按钮
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.build),
                    label: const Text('标记已更换'),
                    onPressed: () => _markReplaced(consumable),
                  ),
                ),
                const SizedBox(height: 16),
                // 更换记录
                const Text(
                  '更换记录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (records.isEmpty)
                  const Text('暂无更换记录', style: TextStyle(color: Colors.grey))
                else
                  ...records.map(
                    (r) => ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(_formatTimestamp(r.replacedAt)),
                      subtitle: Text(
                        '¥${r.price.toStringAsFixed(0)}${r.note?.isNotEmpty == true ? " · ${r.note}" : ""}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteReplacement(r),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 标记更换
  Future<void> _markReplaced(ConsumableRecord consumable) async {
    final priceController = TextEditingController(
      text: consumable.price.toStringAsFixed(0),
    );
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('更换 ${consumable.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '花费金额',
                prefixText: '¥',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认更换'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final record = ReplacementRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        consumableName: consumable.name,
        replacedAt: DateTime.now().millisecondsSinceEpoch,
        price: double.tryParse(priceController.text) ?? consumable.price,
        note: noteController.text.trim(),
      );

      final newReplacements = [..._currentAsset.replacements, record];
      final updatedAsset = _currentAsset.copyWith(
        replacements: newReplacements,
      );
      await context.read<AssetProvider>().saveAsset(updatedAsset);

      if (mounted) setState(() {});
    }
  }

  /// 删除更换记录
  Future<void> _deleteReplacement(ReplacementRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确定删除 ${record.consumableName} 的更换记录？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newReplacements = _currentAsset.replacements
          .where((r) => r.id != record.id)
          .toList();
      final updatedAsset = _currentAsset.copyWith(
        replacements: newReplacements,
      );
      await context.read<AssetProvider>().saveAsset(updatedAsset);
      if (mounted) setState(() {});
    }
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

  /// 获取格式化的天数
  Future<String> _getFormattedDays(int? days) async {
    if (days == null) return Future.value('');
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('time_display_mode') ?? 'auto';
    return TimeFormatter.formatDays(days, mode: mode);
  }

  // ========== V2.1: 分享功能 ==========

  /// 处理分享按钮点击 - V2.1 体验修复：解耦二维码展示与保存动作
  Future<void> _handleShareAsset() async {
    // 第一步：直接弹出二维码对话框（面对面分享，不涉及权限申请）
    final jsonData = _serializeAssetToJson(_currentAsset);
    if (mounted) {
      await _showQRCodeDialog(jsonData);
    }
  }

  /// 将资产序列化为 JSON（保留 id 用于去重，仅剔除本地失效的 avatarPath）
  String _serializeAssetToJson(Asset asset) {
    final Map<String, dynamic> data = {
      'id': asset.id, // V2.1: 保留 id 用于扫码去重
      'assetName': asset.assetName,
      'purchasePrice': asset.purchasePrice,
      'purchaseDate': asset.purchaseDate,
      'expectedLifespanDays': asset.expectedLifespanDays,
      'status': asset.status,
      'category': asset.category,
      'tags': asset.tags,
      'excludeFromTotal': asset.excludeFromTotal,
      'excludeFromDaily': asset.excludeFromDaily,
      'soldPrice': asset.soldPrice,
      'soldDate': asset.soldDate,
      'createdAt': asset.createdAt,
      'isPinned': asset.isPinned,
      // 注意：不包含 avatarPath（本地路径在其他设备上无效）
    };
    return jsonEncode(data);
  }

  /// 显示二维码对话框 - 包含手动保存按钮
  Future<void> _showQRCodeDialog(String jsonData) async {
    final ScreenshotController screenshotController = ScreenshotController();
    bool? saveSuccess;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('分享资产'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 二维码区域：使用 Screenshot 包裹，白色背景防止相册背景变黑
              SizedBox(
                width: 260,
                height: 260,
                child: Screenshot(
                  controller: screenshotController,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: jsonData,
                      version: QrVersions.auto,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 第二步：手动保存按钮
              ElevatedButton.icon(
                onPressed: () async {
                  saveSuccess = await _saveQRCodeToGallery(
                    screenshotController,
                  );
                  if (saveSuccess == true && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                icon: const Icon(Icons.save_alt),
                label: const Text('保存到相册'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );

    // 对话框关闭后显示反馈（避免 BuildContext 跨异步间隙问题）
    if (mounted && saveSuccess != null) {
      if (saveSuccess == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已成功保存至相册'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 保存二维码到相册 - 使用 gal 插件处理权限
  /// 返回 true 表示保存成功，false 表示失败
  Future<bool> _saveQRCodeToGallery(
    ScreenshotController screenshotController,
  ) async {
    try {
      // 权限申请：使用 gal 插件的内置权限管理
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }

      // 截图并保存
      final bytes = await screenshotController.capture();
      if (bytes != null) {
        await Gal.putImageBytes(bytes);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ========== V2.1: 删除功能 ==========

  /// 处理删除按钮点击
  Future<void> _handleDeleteAsset() async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要彻底删除「${_currentAsset.assetName}」吗？\n\n此操作将删除资产记录和相关图片文件，不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text('彻底删除', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 通过 Provider 删除资产
        await context.read<AssetProvider>().deleteAsset(_currentAsset.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('资产已彻底删除'),
              backgroundColor: Colors.orange,
            ),
          );
          // 退回主页并传递刷新信号
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

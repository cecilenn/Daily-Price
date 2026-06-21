import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../services/asset_share_service.dart';
import '../widgets/asset_detail_cards.dart';
import '../widgets/asset_detail_consumables.dart';
import '../widgets/asset_qr_share_dialog.dart';
import '../widgets/asset_record_dialogs.dart';
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
  final bool _isRefreshing = false;

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
            AssetDetailHeaderImage(asset: asset),
            const SizedBox(height: 16),
            // 详情信息卡片
            AssetBasicInfoCard(asset: asset),
            const SizedBox(height: 8),
            // 状态信息卡片
            AssetStatusInfoCard(asset: asset),
            const SizedBox(height: 8),
            // 其他信息卡片
            AssetExtraInfoCard(asset: asset),
            const SizedBox(height: 8),
            // 耗材管理区域
            if (asset.hasConsumables) ...[
              AssetConsumablesCard(
                asset: asset,
                onConsumableTap: _showConsumableDetail,
              ),
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

  /// 显示耗材详情
  void _showConsumableDetail(ConsumableRecord consumable) {
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
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return AssetConsumableDetailSheet(
                asset: _currentAsset,
                consumable: consumable,
                onMarkReplaced: () => _markReplaced(consumable, setSheetState),
                onDeleteReplacement: (record) =>
                    _deleteReplacement(record, setSheetState),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 标记更换
  Future<void> _markReplaced(
    ConsumableRecord consumable,
    StateSetter? setSheetState,
  ) async {
    final result = await showReplacementDialog(
      context,
      title: '更换 ${consumable.name}',
      initialPrice: consumable.price,
      confirmLabel: '确认更换',
    );
    if (result != null) {
      if (!mounted) return;
      final record = ReplacementRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        consumableName: consumable.name,
        replacedAt: result.replacedAt.millisecondsSinceEpoch,
        price: result.price,
        note: null,
      );
      final newReplacements = [..._currentAsset.replacements, record];
      final updatedAsset = _currentAsset.copyWith(
        replacements: newReplacements,
      );
      final provider = context.read<AssetProvider>();
      await provider.saveAsset(updatedAsset);
      if (mounted) {
        setState(() {
          _currentAsset = updatedAsset;
        });
        setSheetState?.call(() {});
      }
    }
  }

  /// 删除更换记录
  Future<void> _deleteReplacement(
    ReplacementRecord record,
    StateSetter? setSheetState,
  ) async {
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
      if (!mounted) return;
      final newReplacements = _currentAsset.replacements
          .where((r) => r.id != record.id)
          .toList();
      final updatedAsset = _currentAsset.copyWith(
        replacements: newReplacements,
      );
      final provider = context.read<AssetProvider>();
      await provider.saveAsset(updatedAsset);
      if (mounted) {
        setState(() {
          _currentAsset = updatedAsset;
        });
        setSheetState?.call(() {});
      }
    }
  }

  // ========== V2.1: 分享功能 ==========

  /// 处理分享按钮点击 - V2.1 体验修复：解耦二维码展示与保存动作
  Future<void> _handleShareAsset() async {
    final saveSuccess = await showDialog<bool>(
      context: context,
      builder: (context) => AssetQrShareDialog(
        jsonData: AssetShareService.serializeToQrJson(_currentAsset),
      ),
    );

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
        if (!mounted) return;
        final provider = context.read<AssetProvider>();
        await provider.deleteAsset(_currentAsset.id);

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

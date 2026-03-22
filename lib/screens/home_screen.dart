import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';
import '../services/local_db_service.dart';
import '../widgets/smart_asset_avatar.dart';
import 'asset_detail_screen.dart';
import 'add_edit_asset_screen.dart';
import 'scanner_screen.dart';

/// 首页 - 资产列表与管理页面（V2.0 重构版）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 资产列表
  List<Asset> _assets = [];
  bool _isLoading = true;
  String? _errorMessage;

  // 当前分栏
  String _currentCategory = 'all';

  // 排序状态
  String _sortBy = 'created_at';
  bool _sortAscending = false;

  // 自定义分栏列表
  List<String> _customTabs = [];

  // SharedPreferences 键名
  static const String _prefKeyCategory = 'home_current_category';
  static const String _prefKeySortBy = 'home_sort_by';
  static const String _prefKeySortAscending = 'home_sort_ascending';
  static const String _customTabsPrefKey = 'custom_tabs';
  static const String _defaultStartupCategoryKey = 'default_startup_category';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  /// 初始化数据
  Future<void> _initData() async {
    await _loadPreferences();
    await _loadCustomTabs();
    await _loadAssets();
  }

  /// 从 SharedPreferences 加载用户偏好设置
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCategory = prefs.getString(_prefKeyCategory);
    final defaultStartupCategory = prefs.getString(_defaultStartupCategoryKey);
    final category = savedCategory ?? defaultStartupCategory ?? 'all';
    final sortBy = prefs.getString(_prefKeySortBy) ?? 'created_at';
    final sortAscending = prefs.getBool(_prefKeySortAscending) ?? false;

    if (mounted) {
      setState(() {
        _currentCategory = category;
        _sortBy = sortBy;
        _sortAscending = sortAscending;
      });
    }
  }

  /// 保存当前分栏设置
  Future<void> _saveCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyCategory, category);
    setState(() {
      _currentCategory = category;
    });
  }

  /// 保存排序设置
  Future<void> _saveSortSettings(String sortBy, bool ascending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeySortBy, sortBy);
    await prefs.setBool(_prefKeySortAscending, ascending);
    setState(() {
      _sortBy = sortBy;
      _sortAscending = ascending;
    });
  }

  /// 加载自定义分栏列表
  Future<void> _loadCustomTabs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customTabs = prefs.getStringList(_customTabsPrefKey) ?? [];
    });
  }

  /// 加载资产数据
  Future<void> _loadAssets({bool isRefresh = false}) async {
    if (_assets.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final assets = await LocalDbService().getAllAssets();

      if (mounted) {
        setState(() {
          _assets = assets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_assets.isEmpty) {
            _errorMessage = '加载数据失败：$e';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 切换置顶状态
  Future<void> _togglePinned(Asset asset) async {
    try {
      final updatedAsset = asset.copyWith(
        isPinned: asset.isPinned == 0 ? 1 : 0,
      );
      await LocalDbService().saveAsset(updatedAsset);
      await _loadAssets(isRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(asset.isPinned == 1 ? '已取消置顶' : '已置顶'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 删除资产
  Future<void> _deleteAsset(Asset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${asset.assetName}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await LocalDbService().deleteAsset(asset.id);
        await _loadAssets(isRefresh: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('资产已删除'),
              backgroundColor: Colors.orange,
            ),
          );
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

  /// 格式化金额
  String _formatCurrency(double? amount) {
    if (amount == null) return '-';
    return '¥${amount.toStringAsFixed(2)}';
  }

  /// 格式化天数
  String _formatDays(int? days) {
    if (days == null) return '-';
    return Asset.formatDays(days, style: 'combined');
  }

  /// 格式化日期戳为字符串
  String _formatDateFromTimestamp(int? timestamp) {
    if (timestamp == null) return '-';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 获取全局统计数据
  Map<String, dynamic> _calculateStats() {
    double totalAssets = 0;
    double dailyCost = 0;
    int activeCount = 0;
    int retiredCount = 0;
    int soldCount = 0;

    for (final asset in _assets) {
      // 统计状态
      if (asset.status == 0) {
        activeCount++;
      } else if (asset.status == 1) {
        retiredCount++;
      } else if (asset.status == 2) {
        soldCount++;
      }

      // 计算总资产（排除 excludeFromTotal）
      if (asset.excludeFromTotal == 0 && asset.purchasePrice != null) {
        totalAssets += asset.purchasePrice!;
      }

      // 计算日均消费（排除 excludeFromDaily）
      if (asset.excludeFromDaily == 0) {
        dailyCost += asset.dailyCost;
      }
    }

    return {
      'totalAssets': totalAssets,
      'dailyCost': dailyCost,
      'activeCount': activeCount,
      'retiredCount': retiredCount,
      'soldCount': soldCount,
    };
  }

  /// 获取过滤后的资产列表
  List<Asset> get _filteredAssets {
    List<Asset> filtered;

    if (_currentCategory == 'all') {
      filtered = List.from(_assets);
    } else if (_currentCategory == 'pinned') {
      filtered = _assets.where((a) => a.isPinned == 1).toList();
    } else if (_currentCategory.startsWith('custom_')) {
      filtered = _assets
          .where((a) => a.tags.contains(_currentCategory))
          .toList();
    } else {
      filtered = _assets.where((a) => a.category == _currentCategory).toList();
    }

    // V2.0 置顶优先级排序：isPinned 永远排第一
    filtered.sort((a, b) {
      // 第一排序规则：置顶优先
      if (a.isPinned != b.isPinned) {
        return b.isPinned - a.isPinned;
      }

      // 第二排序规则：用户选择的排序字段
      int result;
      switch (_sortBy) {
        case 'name':
          result = a.assetName.compareTo(b.assetName);
          break;
        case 'purchase_date':
          result = a.purchaseDate.compareTo(b.purchaseDate);
          break;
        case 'price':
          final priceA = a.purchasePrice ?? 0;
          final priceB = b.purchasePrice ?? 0;
          result = priceA.compareTo(priceB);
          break;
        case 'created_at':
        default:
          result = a.createdAt.compareTo(b.createdAt);
      }
      return _sortAscending ? result : -result;
    });

    return filtered;
  }

  /// 获取分栏显示名称
  String _getCategoryLabel(String value) {
    switch (value) {
      case 'pinned':
        return '置顶';
      case 'physical':
        return '实体资产';
      case 'virtual':
        return '虚拟资产';
      case 'subscription':
        return '限时资产';
      default:
        if (value.startsWith('custom_')) {
          return value.substring(7);
        }
        return '全部';
    }
  }

  /// 获取排序字段显示名称
  String _getSortByLabel(String value) {
    switch (value) {
      case 'name':
        return '名称';
      case 'purchase_date':
        return '购买日期';
      case 'price':
        return '价格';
      case 'created_at':
      default:
        return '添加日期';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAssets = _filteredAssets;
    final stats = _calculateStats();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getCategoryLabel(_currentCategory),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        elevation: 0,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.folder_outlined),
              tooltip: '分栏',
              onSelected: (value) => _saveCategory(value),
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[
                  const PopupMenuItem(value: 'all', child: Text('全部')),
                  const PopupMenuItem(value: 'pinned', child: Text('置顶')),
                  const PopupMenuItem(value: 'physical', child: Text('实体资产')),
                  const PopupMenuItem(value: 'virtual', child: Text('虚拟资产')),
                  const PopupMenuItem(
                    value: 'subscription',
                    child: Text('限时资产'),
                  ),
                ];
                if (_customTabs.isNotEmpty) {
                  items.add(const PopupMenuDivider());
                  for (final tab in _customTabs) {
                    items.add(
                      PopupMenuItem(
                        value: 'custom_$tab',
                        child: Row(
                          children: [
                            const Icon(Icons.label_outline, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                tab,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }
                return items;
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: '排序',
              onSelected: (value) {
                if (value == 'toggle_order') {
                  _saveSortSettings(_sortBy, !_sortAscending);
                } else {
                  _saveSortSettings(value, _sortAscending);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'created_at',
                  child: Row(
                    children: [
                      if (_sortBy == 'created_at')
                        const Icon(Icons.check, size: 18),
                      const SizedBox(width: 8),
                      const Text('添加日期'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      if (_sortBy == 'name') const Icon(Icons.check, size: 18),
                      const SizedBox(width: 8),
                      const Text('名称'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'purchase_date',
                  child: Row(
                    children: [
                      if (_sortBy == 'purchase_date')
                        const Icon(Icons.check, size: 18),
                      const SizedBox(width: 8),
                      const Text('购买日期'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'price',
                  child: Row(
                    children: [
                      if (_sortBy == 'price') const Icon(Icons.check, size: 18),
                      const SizedBox(width: 8),
                      const Text('价格'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'toggle_order',
                  child: Row(
                    children: [
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(_sortAscending ? '升序' : '降序'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        leadingWidth: 100,
        actions: [
          // V2.1: 扫码入库按钮
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _handleScanQRCode(),
            tooltip: '扫码入库',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadAssets(isRefresh: true),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // V2.0 新增：顶部数据统计卡片
                  _buildStatsCard(stats),
                  const SizedBox(height: 8),
                  // 资产列表标题
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getCategoryLabel(_currentCategory),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '共 ${filteredAssets.length} 项',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 40,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _loadAssets,
                              icon: const Icon(Icons.refresh),
                              label: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (filteredAssets.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 40,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _assets.isEmpty ? '暂无资产数据' : '当前分栏暂无资产',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _assets.isEmpty
                                  ? '点击右上角 + 添加您的第一个资产'
                                  : '切换其他分栏查看或添加新资产',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      padding: const EdgeInsets.only(
                        bottom: 120,
                        left: 4,
                        right: 4,
                        top: 4,
                      ),
                      itemCount: filteredAssets.length,
                      itemBuilder: (context, index) =>
                          _buildAssetCard(filteredAssets[index]),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// V2.0 新增：构建顶部数据统计卡片
  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '全局统计',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.account_balance_wallet,
                    label: '总资产',
                    value: _formatCurrency(stats['totalAssets']),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.trending_up,
                    label: '日均消费',
                    value: _formatCurrency(stats['dailyCost']),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle,
                    label: '服役中',
                    value: '${stats['activeCount']}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.pause_circle,
                    label: '已退役',
                    value: '${stats['retiredCount']}',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.money,
                    label: '已卖出',
                    value: '${stats['soldCount']}',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计子项
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// 构建资产卡片（V2.0 双列网格紧凑型卡片）
  Widget _buildAssetCard(Asset asset) {
    // 状态颜色指示器
    final statusColor = _getStatusColor(asset.status);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: asset.status == 2 ? Colors.grey.shade200 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          // 点击跳转到详情页并等待返回信号
          final bool? shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssetDetailScreen(asset: asset),
            ),
          );
          // 只要详情页返回了 true（删除、修改或扫码入库），就触发刷新
          if (shouldRefresh == true && mounted) {
            await _loadAssets(isRefresh: true);
          }
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 顶部：状态指示器 + 置顶标记
                  SizedBox(
                    height: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 状态颜色小圆点
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        // 置顶标记（如有）
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

                  // 中部：资产头像（精致居中）
                  _buildAvatarLarge(asset),
                  const SizedBox(height: 6),

                  // 中部：资产名称（最多1行）
                  Text(
                    asset.assetName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: asset.status == 2
                          ? TextDecoration.lineThrough
                          : null,
                      color: asset.status == 2
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // 底部：日均成本（突出显示，主题色）
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 日均成本 - 带标签突出显示
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
                      // 购入价格 - 带标签弱化显示
                      Text(
                        '买入: ${_formatCurrency(asset.purchasePrice)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 已卖出印章（半透明覆盖）
            if (asset.status == 2)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100.withValues(alpha: 0.3),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red.shade300,
                            width: 1.2,
                          ),
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
              ),
          ],
        ),
      ),
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(int status) {
    switch (status) {
      case 0: // 服役中
        return Colors.green;
      case 1: // 已退役
        return Colors.grey;
      case 2: // 已卖出
        return Colors.red.shade400;
      default:
        return Colors.blue;
    }
  }

  /// 构建大头像（网格卡片专用）- V3.0 使用 SmartAssetAvatar
  Widget _buildAvatarLarge(Asset asset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SmartAssetAvatar(
        asset: asset,
        radius: 24, // 48x48 的圆角矩形效果
      ),
    );
  }

  /// 构建头像 - V3.0 使用 SmartAssetAvatar
  Widget _buildAvatar(Asset asset) {
    return SmartAssetAvatar(asset: asset, radius: 24);
  }

  /// 跳转到添加资产页面
  Future<void> _navigateToAddAsset() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAssetScreen()),
    );
    if (result == true && mounted) {
      await _loadAssets(isRefresh: true);
    }
  }

  /// 跳转到编辑资产页面
  Future<void> _navigateToEditAsset(Asset asset) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAssetScreen(existingAsset: asset),
      ),
    );
    if (result == true && mounted) {
      await _loadAssets(isRefresh: true);
    }
  }

  // ========== V2.1: 扫码入库功能（防抖重构版）==========

  /// 处理扫码按钮点击
  Future<void> _handleScanQRCode() async {
    // 检查并申请相机权限
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('需要相机权限才能扫码'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // 打开独立扫码页面并获取返回值
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );

    // 用户取消或未识别到二维码时，result 为 null
    if (result == null || !mounted) return;

    // 处理扫码结果（包含异常处理）
    await _processScannedQRCode(result);
  }

  /// V2.1: 处理扫描到的二维码数据（终极重构版 - 基于唯一 ID 去重）
  Future<void> _processScannedQRCode(String qrData) async {
    try {
      // 尝试解析 JSON
      final Map<String, dynamic> jsonData = jsonDecode(qrData);

      // 验证是否为合法的资产二维码（必须包含关键字段）
      if (jsonData['assetName'] == null && jsonData['asset_name'] == null) {
        throw FormatException('缺少资产名称字段');
      }

      // V2.1: 从 JSON 中提取原始 id（去重关键）
      final String? originalId = jsonData['id'] as String?;

      // 创建扫描资产对象（使用原始 id，确保 avatarPath 为 null）
      final scannedAsset = Asset(
        id: originalId ?? const Uuid().v4(), // 优先使用原始 id，否则生成新 UUID
        assetName:
            jsonData['assetName'] as String? ??
            jsonData['asset_name'] as String? ??
            '未知资产',
        purchasePrice:
            (jsonData['purchasePrice'] as num?)?.toDouble() ??
            (jsonData['purchase_price'] as num?)?.toDouble(),
        purchaseDate:
            jsonData['purchaseDate'] as int? ??
            jsonData['purchase_date'] as int? ??
            DateTime.now().millisecondsSinceEpoch,
        expectedLifespanDays:
            jsonData['expectedLifespanDays'] as int? ??
            jsonData['expected_lifespan_days'] as int?,
        status: jsonData['status'] as int? ?? 0, // 保留原始状态
        category: jsonData['category'] as String? ?? 'physical',
        tags: jsonData['tags'] is List
            ? (jsonData['tags'] as List).map((e) => e.toString()).toList()
            : [],
        createdAt:
            jsonData['createdAt'] as int? ??
            jsonData['created_at'] as int? ??
            DateTime.now().millisecondsSinceEpoch,
        isPinned:
            jsonData['isPinned'] as int? ?? jsonData['is_pinned'] as int? ?? 0,
        excludeFromTotal:
            jsonData['excludeFromTotal'] as int? ??
            jsonData['exclude_from_total'] as int? ??
            0,
        excludeFromDaily:
            jsonData['excludeFromDaily'] as int? ??
            jsonData['exclude_from_daily'] as int? ??
            0,
        soldPrice:
            (jsonData['soldPrice'] as num?)?.toDouble() ??
            (jsonData['sold_price'] as num?)?.toDouble(),
        soldDate: jsonData['soldDate'] as int? ?? jsonData['sold_date'] as int?,
        avatarPath: null, // 强制设为 null（本地路径在其他设备上无效）
      );

      // V2.1: 去重引擎 - 按原始 id 查询是否已存在
      Asset? existingAsset;
      if (originalId != null && originalId.isNotEmpty) {
        existingAsset = await LocalDbService().getAssetById(originalId);
      }

      if (existingAsset != null) {
        // ========== 分支 A：已存在 ==========
        if (mounted) {
          // 弹出提示框
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('资产已存在'),
              content: Text('「${existingAsset!.assetName}」已在您的库存中。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('确定'),
                ),
              ],
            ),
          );

          // 普通模式跳转到详情页，等待返回信号
          final bool? shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetDetailScreen(asset: existingAsset!),
            ),
          );
          // 如果详情页返回 true（删除操作），刷新主页列表
          if (shouldRefresh == true && mounted) {
            await _loadAssets(isRefresh: true);
          }
        }
      } else {
        // ========== 分支 B：新发现 ==========
        // 预览模式跳转（显示「加入我的库存」按钮）
        final isAdded = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AssetDetailScreen(asset: scannedAsset, isPreview: true),
          ),
        );

        // 如果用户点击了「加入我的库存」，刷新主页列表
        if (isAdded == true && mounted) {
          await _loadAssets(isRefresh: true);
        }
      }
    } catch (e) {
      // 解析失败：显示红色 SnackBar 提示"无法识别的资产二维码"
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法识别的资产二维码'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../services/local_db_service.dart';
import '../services/asset_filter_sorter.dart';
import '../utils/stats_calculator.dart';
import '../widgets/smart_asset_avatar.dart';
import 'asset_detail_screen.dart';
import 'scanner_screen.dart';

/// 首页 - 资产列表与管理页面（V2.0 重构版）
class HomeScreen extends StatefulWidget {
  final ValueNotifier<bool>? hideDockNotifier;

  const HomeScreen({super.key, this.hideDockNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 当前分栏
  String _currentCategory = 'all';

  // 排序状态
  String _sortBy = 'created_at';
  bool _sortAscending = false;

  // 搜索状态
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // 筛选状态
  int? _statusFilter;
  Set<String> _selectedCategories = {};
  Set<String> _selectedTags = {};
  RangeValues? _priceRange;

  // 多选状态
  bool _isMultiSelectMode = false;
  Set<String> _selectedAssetIds = {};

  /// 更新多选模式状态并通知父级
  void _setMultiSelectMode(bool value) {
    setState(() {
      _isMultiSelectMode = value;
    });
    widget.hideDockNotifier?.value = value;
  }

  // 自定义分栏列表
  List<String> _customTabs = [];

  // 自定义分类列表
  List<String> _customCategories = ['未分类'];

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
    await _loadCustomCategories();
    // 资产数据由 AssetProvider 管理，不需要在这里加载
  }

  /// 从 SharedPreferences 加载用户偏好设置
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCategory = prefs.getString(_prefKeyCategory);
    final defaultStartupCategory = prefs.getString(_defaultStartupCategoryKey);

    // 如果有保存的分类，使用保存的；否则使用默认启动分类
    String category;
    if (savedCategory != null) {
      category = savedCategory;
    } else if (defaultStartupCategory != null &&
        defaultStartupCategory.isNotEmpty) {
      category = defaultStartupCategory;
    } else {
      category = 'all';
    }

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

  /// 加载自定义分类列表
  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customCategories = prefs.getStringList('custom_categories') ?? ['未分类'];
    });
  }

  // 资产数据由 AssetProvider 管理，不再需要 _loadAssets 方法

  /// 格式化金额
  String _formatCurrency(double? amount) {
    if (amount == null) return '-';
    return '¥${amount.toStringAsFixed(2)}';
  }

  /// 格式化时间戳为 yyyy-MM-dd 格式（CSV 导出专用）
  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 资产数据由 AssetProvider 管理，不再需要本地计算方法

  /// 获取分栏显示名称
  String _getCategoryLabel(String value) {
    if (value == 'all') {
      return '全部';
    }
    // 直接返回分类名称（因为现在是自定义分类）
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssetProvider>(
      builder: (context, provider, child) {
        final filteredAssets = AssetFilterSorter.filterAndSort(
          assets: provider.assets,
          category: _currentCategory,
          sortBy: _sortBy,
          ascending: _sortAscending,
          searchQuery: _searchQuery,
          statusFilter: _statusFilter,
          categoryFilters: _selectedCategories.isNotEmpty
              ? _selectedCategories
              : null,
          tagFilters: _selectedTags.isNotEmpty ? _selectedTags : null,
          priceRange: _priceRange,
        );
        final stats = StatsCalculator.calculate(provider.assets);

        return Scaffold(
          appBar: _isMultiSelectMode
              ? _buildMultiSelectAppBar(filteredAssets)
              : _isSearching
              ? _buildSearchAppBar()
              : _buildNormalAppBar(),
          body: PopScope(
            canPop: !_isMultiSelectMode,
            onPopInvokedWithResult: (didPop, result) {
              if (_isMultiSelectMode) {
                _setMultiSelectMode(false);
                setState(() {
                  _selectedAssetIds.clear();
                });
              }
            },
            child: RefreshIndicator(
              onRefresh: () async => await provider.loadAssets(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 40,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                provider.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () async =>
                                    await provider.loadAssets(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('重试'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredAssets.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 40,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                provider.assets.isEmpty ? '暂无资产数据' : '当前分栏暂无资产',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                provider.assets.isEmpty
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
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom: _isMultiSelectMode ? 80 : 120,
                          left: 4,
                          right: 4,
                          top: 4,
                        ),
                        children: [
                          // V2.0 新增：顶部数据统计卡片（可随内容滚动）
                          if (!_isMultiSelectMode) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                              child: _buildStatsCard(stats),
                            ),
                            const SizedBox(height: 8),
                          ],
                          // 资产列表标题
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isMultiSelectMode
                                      ? '已选 ${_selectedAssetIds.length} 项'
                                      : _getCategoryLabel(_currentCategory),
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
                          ),
                          const SizedBox(height: 8),
                          // 资产网格（嵌入到 ListView 中）
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final cardWidth = (constraints.maxWidth - 10) / 2;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: filteredAssets
                                    .map(
                                      (asset) => SizedBox(
                                        width: cardWidth,
                                        child: _buildAssetCard(asset),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                        ],
                      ),
              ),
            ),
          ),
          bottomSheet: _isMultiSelectMode
              ? _buildMultiSelectBottomSheet()
              : null,
        );
      },
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
    final isSelected = _selectedAssetIds.contains(asset.id);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _isMultiSelectMode && isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
          : asset.status == 2
          ? Colors.grey.shade200
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          if (_isMultiSelectMode) {
            // 多选模式下点击切换选中状态
            setState(() {
              if (_selectedAssetIds.contains(asset.id)) {
                _selectedAssetIds.remove(asset.id);
              } else {
                _selectedAssetIds.add(asset.id);
              }
            });
          } else {
            // 普通模式点击跳转到详情页
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssetDetailScreen(asset: asset),
              ),
            );
            // Provider 会自动通知 UI 更新，无需手动刷新
          }
        },
        onLongPress: () {
          // 长按进入多选模式
          if (!_isMultiSelectMode) {
            _setMultiSelectMode(true);
            setState(() {
              _selectedAssetIds.add(asset.id);
            });
          }
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 顶部：状态指示器 + 复选框/置顶标记
                  SizedBox(
                    height: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 多选模式显示复选框，否则显示状态颜色小圆点
                        if (_isMultiSelectMode)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedAssetIds.add(asset.id);
                                  } else {
                                    _selectedAssetIds.remove(asset.id);
                                  }
                                });
                              },
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
                      // 耗材剩余天数（有耗材才显示，只显示最紧急的1个）
                      if (asset.hasConsumables) ...[
                        const SizedBox(height: 2),
                        Builder(
                          builder: (context) {
                            // 找最紧急的耗材（剩余天数最小的）
                            final urgent = asset.consumables.reduce(
                              (a, b) =>
                                  asset.getConsumableRemainingDays(a) <
                                      asset.getConsumableRemainingDays(b)
                                  ? a
                                  : b,
                            );
                            final remaining = asset.getConsumableRemainingDays(
                              urgent,
                            );
                            final isExpired = remaining < 0;
                            return Text(
                              isExpired
                                  ? '${urgent.name} 已过期${-remaining}天'
                                  : '${urgent.name} ${remaining}天',
                              style: TextStyle(
                                fontSize: 10,
                                color: isExpired
                                    ? Colors.red
                                    : Colors.grey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ],
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

  // 资产数据由 AssetProvider 管理，导航方法已移至 UI 层处理

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

          // 普通模式跳转到详情页
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetDetailScreen(asset: existingAsset!),
            ),
          );
          // Provider 会自动通知 UI 更新，无需手动刷新
        }
      } else {
        // ========== 分支 B：新发现 ==========
        // 预览模式跳转（显示「加入我的库存」按钮）
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AssetDetailScreen(asset: scannedAsset, isPreview: true),
          ),
        );

        // Provider 会自动通知 UI 更新，无需手动刷新
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

  /// 构建普通 AppBar
  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
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
            tooltip: '分类',
            onSelected: (value) => _saveCategory(value),
            onOpened: () => _loadCustomCategories(),
            itemBuilder: (context) {
              final items = <PopupMenuEntry<String>>[
                const PopupMenuItem(value: 'all', child: Text('全部')),
                const PopupMenuDivider(),
                ..._customCategories.map(
                  (c) => PopupMenuItem(value: c, child: Text(c)),
                ),
              ];
              return items;
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '筛选与排序',
            onPressed: _showFilterSortSheet,
          ),
        ],
      ),
      leadingWidth: 100,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '搜索',
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () => _handleScanQRCode(),
          tooltip: '扫码入库',
        ),
      ],
    );
  }

  /// 构建搜索 AppBar
  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearching = false;
            _searchQuery = '';
            _searchController.clear();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '搜索资产名称...',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
      centerTitle: false,
      elevation: 0,
      actions: [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
      ],
    );
  }

  /// 构建多选模式 AppBar
  PreferredSizeWidget _buildMultiSelectAppBar(List<Asset> filteredAssets) {
    final allSelected = _selectedAssetIds.length == filteredAssets.length;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          _setMultiSelectMode(false);
          setState(() {
            _selectedAssetIds.clear();
          });
        },
      ),
      title: Text('已选 ${_selectedAssetIds.length} 项'),
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            allSelected ? Icons.check_box : Icons.check_box_outline_blank,
          ),
          onPressed: () {
            setState(() {
              if (allSelected) {
                _selectedAssetIds.clear();
              } else {
                _selectedAssetIds = filteredAssets.map((a) => a.id).toSet();
              }
            });
          },
        ),
      ],
    );
  }

  /// 构建多选模式底部操作栏
  Widget _buildMultiSelectBottomSheet() {
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
            _buildActionButton(
              icon: Icons.delete,
              label: '删除',
              color: Colors.red,
              onPressed: _selectedAssetIds.isEmpty
                  ? null
                  : _showBatchDeleteConfirm,
            ),
            _buildActionButton(
              icon: Icons.label,
              label: '打标签',
              color: Colors.blue,
              onPressed: _selectedAssetIds.isEmpty ? null : _showBatchTagSheet,
            ),
            _buildActionButton(
              icon: Icons.category,
              label: '改分类',
              color: Colors.orange,
              onPressed: _selectedAssetIds.isEmpty
                  ? null
                  : _showBatchCategoryDialog,
            ),
            _buildActionButton(
              icon: Icons.ios_share,
              label: '分享',
              color: Colors.green,
              onPressed: _selectedAssetIds.isEmpty ? null : _batchShareAssets,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
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

  /// 显示筛选排序 BottomSheet
  void _showFilterSortSheet() {
    _loadCustomTabs(); // 刷新标签数据
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 拖拽指示条
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // 排序部分
                        _buildSortSection(setSheetState),
                        const Divider(),

                        // 状态筛选
                        _buildStatusFilterSection(setSheetState),
                        const Divider(),

                        // 标签筛选
                        if (_customTabs.isNotEmpty) ...[
                          _buildTagFilterSection(setSheetState),
                          const Divider(),
                        ],

                        // 价格区间
                        _buildPriceFilterSection(setSheetState),
                        const SizedBox(height: 24),

                        // 重置按钮
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setSheetState(() {
                                _sortBy = 'created_at';
                                _sortAscending = false;
                                _statusFilter = null;
                                _selectedCategories.clear();
                                _selectedTags.clear();
                                _priceRange = null;
                              });
                              setState(() {});
                              _saveSortSettings('created_at', false);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('重置全部筛选'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建排序部分
  Widget _buildSortSection(void Function(VoidCallback) setStateFn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '排序',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('添加日期'),
              selected: _sortBy == 'created_at',
              onSelected: (selected) {
                if (selected) _saveSortSettings('created_at', _sortAscending);
              },
            ),
            ChoiceChip(
              label: const Text('名称'),
              selected: _sortBy == 'name',
              onSelected: (selected) {
                if (selected) _saveSortSettings('name', _sortAscending);
              },
            ),
            ChoiceChip(
              label: const Text('购入价格'),
              selected: _sortBy == 'price',
              onSelected: (selected) {
                if (selected) _saveSortSettings('price', _sortAscending);
              },
            ),
            ChoiceChip(
              label: const Text('日均消费'),
              selected: _sortBy == 'dailyCost',
              onSelected: (selected) {
                if (selected) _saveSortSettings('dailyCost', _sortAscending);
              },
            ),
            ChoiceChip(
              label: const Text('已用天数'),
              selected: _sortBy == 'daysUsed',
              onSelected: (selected) {
                if (selected) _saveSortSettings('daysUsed', _sortAscending);
              },
            ),
            ChoiceChip(
              label: const Text('剩余天数'),
              selected: _sortBy == 'remainingDays',
              onSelected: (selected) {
                if (selected)
                  _saveSortSettings('remainingDays', _sortAscending);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ChoiceChip(
              label: const Text('升序'),
              selected: _sortAscending,
              onSelected: (selected) {
                if (selected) _saveSortSettings(_sortBy, true);
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('降序'),
              selected: !_sortAscending,
              onSelected: (selected) {
                if (selected) _saveSortSettings(_sortBy, false);
              },
            ),
          ],
        ),
      ],
    );
  }

  /// 构建状态筛选部分
  Widget _buildStatusFilterSection(void Function(VoidCallback) setStateFn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '状态筛选',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('全部'),
              selected: _statusFilter == null,
              onSelected: (selected) {
                if (selected) {
                  setStateFn(() => _statusFilter = null);
                  setState(() {});
                }
              },
            ),
            ChoiceChip(
              label: const Text('服役中'),
              selected: _statusFilter == 0,
              onSelected: (selected) {
                if (selected) {
                  setStateFn(() => _statusFilter = 0);
                  setState(() {});
                }
              },
            ),
            ChoiceChip(
              label: const Text('已退役'),
              selected: _statusFilter == 1,
              onSelected: (selected) {
                if (selected) {
                  setStateFn(() => _statusFilter = 1);
                  setState(() {});
                }
              },
            ),
            ChoiceChip(
              label: const Text('已卖出'),
              selected: _statusFilter == 2,
              onSelected: (selected) {
                if (selected) {
                  setStateFn(() => _statusFilter = 2);
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  /// 构建标签筛选部分
  Widget _buildTagFilterSection(void Function(VoidCallback) setStateFn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '标签筛选',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _customTabs.map((tab) {
            final tag = 'custom_$tab';
            return FilterChip(
              label: Text(tab),
              selected: _selectedTags.contains(tag),
              onSelected: (selected) {
                setStateFn(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
                setState(() {});
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建价格筛选部分
  Widget _buildPriceFilterSection(void Function(VoidCallback) setStateFn) {
    return Consumer<AssetProvider>(
      builder: (context, provider, child) {
        // 计算最高价格（1.2 倍向上取整）
        double maxPrice = 10000;
        if (provider.assets.isNotEmpty) {
          final highestPrice = provider.assets
              .where((a) => a.purchasePrice != null)
              .fold(
                0.0,
                (max, a) => a.purchasePrice! > max ? a.purchasePrice! : max,
              );
          if (highestPrice > 0) {
            maxPrice = (highestPrice * 1.2).ceilToDouble();
          }
        }

        // 确保 maxPrice > 0，避免 RangeSlider 出错
        if (maxPrice <= 0) {
          maxPrice = 10000;
        }

        final currentRange = _priceRange ?? RangeValues(0, maxPrice);

        // 确保 values 在有效范围内
        final validStart = currentRange.start.clamp(0, maxPrice).toDouble();
        final validEnd = currentRange.end.clamp(0, maxPrice).toDouble();
        final validRange = RangeValues(
          validStart <= validEnd ? validStart : validEnd,
          validEnd >= validStart ? validEnd : validStart,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '价格区间',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '¥${validRange.start.toStringAsFixed(0)} — ¥${validRange.end.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: validRange,
              min: 0,
              max: maxPrice,
              divisions: 20,
              labels: RangeLabels(
                '¥${validRange.start.toStringAsFixed(0)}',
                '¥${validRange.end.toStringAsFixed(0)}',
              ),
              onChanged: (values) {
                setStateFn(() {
                  _priceRange = values;
                });
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  /// 显示批量删除确认对话框
  void _showBatchDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定删除 ${_selectedAssetIds.length} 项资产？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _batchDeleteAssets();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 批量删除资产
  Future<void> _batchDeleteAssets() async {
    final provider = context.read<AssetProvider>();
    int deletedCount = 0;

    for (final id in _selectedAssetIds) {
      try {
        await provider.deleteAsset(id);
        deletedCount++;
      } catch (e) {
        // 继续删除其他资产
      }
    }

    if (mounted) {
      _setMultiSelectMode(false);
      setState(() {
        _selectedAssetIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除 $deletedCount 项资产'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// 显示批量打标签 BottomSheet
  void _showBatchTagSheet() {
    _loadCustomTabs(); // 刷新标签数据
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '选择要添加的标签',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_customTabs.isEmpty)
                  const Text('暂无自定义标签')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _customTabs.map((tab) {
                      return FilterChip(
                        label: Text(tab),
                        selected: false,
                        onSelected: (selected) {
                          if (selected) {
                            Navigator.pop(context);
                            _batchAddTag('custom_$tab');
                          }
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 批量添加标签
  Future<void> _batchAddTag(String tag) async {
    final provider = context.read<AssetProvider>();
    int updatedCount = 0;

    for (final id in _selectedAssetIds) {
      final asset = provider.assets.firstWhere((a) => a.id == id);
      if (!asset.tags.contains(tag)) {
        final updatedAsset = asset.copyWith(tags: [...asset.tags, tag]);
        await provider.saveAsset(updatedAsset);
        updatedCount++;
      }
    }

    if (mounted) {
      _setMultiSelectMode(false);
      setState(() {
        _selectedAssetIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已为 $updatedCount 项资产添加标签'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  /// 显示批量改分类对话框
  void _showBatchCategoryDialog() {
    _loadCustomCategories(); // 刷新分类数据
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择分类'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _customCategories
              .map(
                (category) => ListTile(
                  title: Text(category),
                  onTap: () {
                    Navigator.pop(context);
                    _batchUpdateCategory(category);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  /// 批量更新分类
  Future<void> _batchUpdateCategory(String category) async {
    final provider = context.read<AssetProvider>();
    int updatedCount = 0;

    for (final id in _selectedAssetIds) {
      final asset = provider.assets.firstWhere((a) => a.id == id);
      if (asset.category != category) {
        final updatedAsset = asset.copyWith(category: category);
        await provider.saveAsset(updatedAsset);
        updatedCount++;
      }
    }

    if (mounted) {
      _setMultiSelectMode(false);
      setState(() {
        _selectedAssetIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已更新 $updatedCount 项资产的分类'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// 批量分享资产
  Future<void> _batchShareAssets() async {
    final provider = context.read<AssetProvider>();
    final selectedAssets = provider.assets
        .where((a) => _selectedAssetIds.contains(a.id))
        .toList();

    if (selectedAssets.isEmpty) return;

    // 构建 CSV（与 SettingsScreen 格式一致）
    final csvData = <List<dynamic>>[
      [
        'id',
        'asset_name',
        'purchase_price',
        'expected_lifespan_days',
        'purchase_date',
        'is_pinned',
        'status',
        'sold_price',
        'sold_date',
        'category',
        'expire_date',
        'tags',
        'created_at',
      ],
    ];

    for (final asset in selectedAssets) {
      csvData.add([
        asset.id,
        asset.assetName,
        asset.purchasePrice ?? '',
        asset.expectedLifespanDays ?? '',
        _formatTimestamp(asset.purchaseDate),
        asset.isPinned == 1 ? 'true' : 'false',
        asset.status,
        asset.soldPrice ?? '',
        _formatTimestamp(asset.soldDate),
        asset.category,
        _formatTimestamp(asset.expireDate),
        asset.tags.join(';'),
        _formatTimestamp(asset.createdAt),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final defaultFileName = 'daily_price_selected_$timestamp.csv';

    try {
      if (kIsWeb) {
        // Web 平台暂不支持批量导出
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web 平台暂不支持批量导出'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 使用 FilePicker 保存文件
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: '保存 CSV 文件',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList(utf8.encode(csvString)),
      );

      if (savePath == null) {
        // 用户取消保存
        return;
      }

      if (savePath.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已保存到：$savePath'),
              backgroundColor: Colors.green,
            ),
          );

          // 保存完成后退出多选模式
          _setMultiSelectMode(false);
          setState(() {
            _selectedAssetIds.clear();
          });
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败：${e.code} - ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

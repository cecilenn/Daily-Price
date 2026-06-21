import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../models/asset_category.dart';
import '../providers/asset_provider.dart';
import '../services/asset_batch_service.dart';
import '../services/asset_export_service.dart';
import '../services/asset_preferences_service.dart';
import '../services/asset_filter_sorter.dart';
import '../services/home_scan_flow.dart';
import '../utils/stats_calculator.dart';
import '../widgets/home_app_bars.dart';
import '../widgets/home_asset_list_content.dart';
import '../widgets/home_asset_card.dart';
import '../widgets/home_batch_sheets.dart';
import '../widgets/home_filter_sort_sheet.dart';
import '../widgets/multi_select_action_bar.dart';
import 'asset_detail_screen.dart';

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
  AssetFilterState _filterState = AssetFilterSorter.emptyFilter;

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

  void _clearMultiSelectMode() {
    _setMultiSelectMode(false);
    setState(() {
      _selectedAssetIds.clear();
    });
  }

  void _showSnack(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  void _finishBatchAction(String message, Color backgroundColor) {
    _clearMultiSelectMode();
    _showSnack(message, backgroundColor);
  }

  // 自定义分栏列表
  List<String> _customTabs = [];

  // 自定义分类列表
  List<String> _customCategories = [AssetCategory.uncategorized];

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
    final preferences = await AssetPreferencesService.loadHomePreferences();

    if (mounted) {
      setState(() {
        _currentCategory = preferences.currentCategory;
        _sortBy = preferences.sortBy;
        _sortAscending = preferences.sortAscending;
      });
    }
  }

  /// 保存当前分栏设置
  Future<void> _saveCategory(String category) async {
    final normalized = AssetPreferencesService.normalizeCategorySelection(
      category,
      fallback: 'all',
    );
    await AssetPreferencesService.saveHomeCategory(normalized);
    setState(() {
      _currentCategory = normalized;
    });
  }

  /// 保存排序设置
  Future<void> _saveSortSettings(String sortBy, bool ascending) async {
    setState(() {
      _sortBy = sortBy;
      _sortAscending = ascending;
    });
    await AssetPreferencesService.saveHomeSortSettings(sortBy, ascending);
  }

  /// 加载自定义分栏列表
  Future<void> _loadCustomTabs() async {
    final tabs = await AssetPreferencesService.loadCustomTabs();
    if (!mounted) return;
    setState(() {
      _customTabs = tabs;
    });
  }

  /// 加载自定义分类列表
  Future<void> _loadCustomCategories() async {
    final categories = await AssetPreferencesService.loadCustomCategories();
    if (!mounted) return;
    setState(() {
      _customCategories = categories;
    });
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
          filterState: _filterState,
        );
        final stats = StatsCalculator.calculate(provider.assets);

        return Scaffold(
          appBar: _isMultiSelectMode
              ? HomeMultiSelectAppBar(
                  selectedCount: _selectedAssetIds.length,
                  allSelected:
                      _selectedAssetIds.length == filteredAssets.length,
                  onClosePressed: () {
                    _clearMultiSelectMode();
                  },
                  onToggleAllPressed: () {
                    setState(() {
                      if (_selectedAssetIds.length == filteredAssets.length) {
                        _selectedAssetIds.clear();
                      } else {
                        _selectedAssetIds = filteredAssets
                            .map((a) => a.id)
                            .toSet();
                      }
                    });
                  },
                )
              : _isSearching
              ? HomeSearchAppBar(
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  onBackPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  onSearchChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onClearPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
              : HomeNormalAppBar(
                  title: _getCategoryLabel(_currentCategory),
                  categories: _customCategories,
                  onCategorySelected: _saveCategory,
                  onCategoryMenuOpened: _loadCustomCategories,
                  onFilterPressed: _showFilterSortSheet,
                  onSearchPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                  onScanPressed: () => HomeScanFlow.handleScanQRCode(context),
                ),
          body: PopScope(
            canPop: !_isMultiSelectMode,
            onPopInvokedWithResult: (didPop, result) {
              if (_isMultiSelectMode) {
                _clearMultiSelectMode();
              }
            },
            child: HomeAssetListContent(
              provider: provider,
              filteredAssets: filteredAssets,
              stats: stats,
              isMultiSelectMode: _isMultiSelectMode,
              selectedCount: _selectedAssetIds.length,
              title: _getCategoryLabel(_currentCategory),
              onRefresh: provider.loadAssets,
              assetBuilder: _buildAssetCard,
            ),
          ),
          bottomSheet: _isMultiSelectMode
              ? MultiSelectActionBar(
                  enabled: _selectedAssetIds.isNotEmpty,
                  onDelete: _showBatchDeleteConfirm,
                  onTag: _showBatchTagSheet,
                  onCategory: _showBatchCategoryDialog,
                  onShare: _batchShareAssets,
                )
              : null,
        );
      },
    );
  }

  /// 构建资产卡片（V2.0 双列网格紧凑型卡片）
  Widget _buildAssetCard(Asset asset) {
    final isSelected = _selectedAssetIds.contains(asset.id);
    return HomeAssetCard(
      asset: asset,
      isMultiSelectMode: _isMultiSelectMode,
      isSelected: isSelected,
      onTap: () async {
        if (_isMultiSelectMode) {
          _toggleAssetSelection(asset.id);
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssetDetailScreen(asset: asset),
            ),
          );
        }
      },
      onLongPress: () {
        if (!_isMultiSelectMode) {
          _setMultiSelectMode(true);
          _toggleAssetSelection(asset.id);
        }
      },
      onSelectedChanged: (value) {
        _setAssetSelected(asset.id, value == true);
      },
    );
  }

  void _toggleAssetSelection(String assetId) {
    setState(() {
      if (_selectedAssetIds.contains(assetId)) {
        _selectedAssetIds.remove(assetId);
      } else {
        _selectedAssetIds.add(assetId);
      }
    });
  }

  void _setAssetSelected(String assetId, bool selected) {
    setState(() {
      if (selected) {
        _selectedAssetIds.add(assetId);
      } else {
        _selectedAssetIds.remove(assetId);
      }
    });
  }

  /// 显示筛选排序 BottomSheet
  Future<void> _showFilterSortSheet() async {
    await _loadCustomTabs();
    await _loadCustomCategories();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => HomeFilterSortSheet(
        sortBy: _sortBy,
        sortAscending: _sortAscending,
        statusFilter: _filterState.statusFilter,
        selectedCategories: _filterState.selectedCategories,
        selectedTags: _filterState.selectedTags,
        priceRange: _filterState.priceRange,
        categories: _customCategories,
        customTabs: _customTabs,
        assets: context.read<AssetProvider>().assets,
        onSortChanged: _saveSortSettings,
        onStatusFilterChanged: (value) {
          setState(() => _filterState = _filterState.withStatus(value));
        },
        onCategoryFiltersChanged: (value) {
          setState(() => _filterState = _filterState.withCategories(value));
        },
        onTagFiltersChanged: (value) {
          setState(() => _filterState = _filterState.withTags(value));
        },
        onPriceRangeChanged: (value) {
          setState(() => _filterState = _filterState.withPriceRange(value));
        },
        onReset: () {
          setState(() => _filterState = AssetFilterSorter.emptyFilter);
          _saveSortSettings('created_at', false);
        },
      ),
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
    final deletedCount = await AssetBatchService.deleteAssets(
      provider,
      _selectedAssetIds,
    );

    if (mounted) {
      _finishBatchAction('已删除 $deletedCount 项资产', Colors.orange);
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
      builder: (context) => HomeBatchTagSheet(
        customTabs: _customTabs,
        onTagSelected: (tag) {
          Navigator.pop(context);
          _batchAddTag(tag);
        },
      ),
    );
  }

  /// 批量添加标签
  Future<void> _batchAddTag(String tag) async {
    final provider = context.read<AssetProvider>();
    final updatedCount = await AssetBatchService.addTag(
      provider,
      _selectedAssetIds,
      tag,
    );

    if (mounted) {
      _finishBatchAction('已为 $updatedCount 项资产添加标签', Colors.blue);
    }
  }

  /// 显示批量改分类对话框
  void _showBatchCategoryDialog() {
    _loadCustomCategories(); // 刷新分类数据
    showDialog(
      context: context,
      builder: (context) => HomeBatchCategoryDialog(
        categories: _customCategories,
        onCategorySelected: (category) {
          Navigator.pop(context);
          _batchUpdateCategory(category);
        },
      ),
    );
  }

  /// 批量更新分类
  Future<void> _batchUpdateCategory(String category) async {
    final provider = context.read<AssetProvider>();
    final updatedCount = await AssetBatchService.updateCategory(
      provider,
      _selectedAssetIds,
      category,
    );

    if (mounted) {
      _finishBatchAction('已更新 $updatedCount 项资产的分类', Colors.orange);
    }
  }

  /// 批量分享资产
  Future<void> _batchShareAssets() async {
    final provider = context.read<AssetProvider>();
    final payload = AssetBatchService.prepareSharePayload(
      provider.assets,
      _selectedAssetIds,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    if (payload == null) return;

    final result = await AssetExportService.saveCsv(
      csvString: payload.csvString,
      defaultFileName: payload.defaultFileName,
    );

    if (!mounted || result.isCanceled) return;

    if (result.isUnsupported) {
      _showSnack(result.errorMessage ?? '当前平台不支持导出', Colors.orange);
      return;
    }

    if (result.isSaved) {
      _finishBatchAction('已保存到：${result.savePath}', Colors.green);
      return;
    }

    if (result.errorMessage != null) {
      _showSnack(result.errorMessage!, Colors.red);
    }
  }
}

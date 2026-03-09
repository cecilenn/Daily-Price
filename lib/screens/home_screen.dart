import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '../providers/app_provider.dart';

/// 首页 - 资产列表与管理页面
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
  String _currentCategory = 'pinned';
  
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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadCustomTabs();
    _loadAssets();
  }
  
  /// 从 SharedPreferences 加载用户偏好设置
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentCategory = prefs.getString(_prefKeyCategory) ?? 'pinned';
      _sortBy = prefs.getString(_prefKeySortBy) ?? 'created_at';
      _sortAscending = prefs.getBool(_prefKeySortAscending) ?? false;
    });
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

  /// 从 Supabase 加载资产数据
  Future<void> _loadAssets({bool isRefresh = false}) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '请先登录';
        _assets = [];
      });
      return;
    }

    if (_assets.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await Supabase.instance.client
          .from('assets')
          .select()
          .eq('user_id', currentUser.id)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        final latestAsset = Asset.fromJson(response.first);
        if (mounted) {
          context.read<AppProvider>().updateSyncTime(latestAsset.createdAt);
        }
      }

      if (mounted) {
        setState(() {
          _assets = (response as List).map((item) => Asset.fromJson(item)).toList();
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
          SnackBar(
            content: Text('加载数据失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 切换置顶状态
  Future<void> _togglePinned(Asset asset) async {
    try {
      await Supabase.instance.client
          .from('assets')
          .update({'is_pinned': !asset.isPinned})
          .eq('id', asset.id!);
      
      await _loadAssets(isRefresh: true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(asset.isPinned ? '已取消置顶' : '已置顶'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败：$e'),
            backgroundColor: Colors.red,
          ),
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
        await Supabase.instance.client
            .from('assets')
            .delete()
            .eq('id', asset.id!);
        
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
            SnackBar(
              content: Text('删除失败：$e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 格式化金额
  String _formatCurrency(double amount) {
    return '¥${amount.toStringAsFixed(2)}';
  }

  /// 格式化天数
  String _formatDays(int days) {
    final appProvider = context.watch<AppProvider>();
    return DateParser.formatDays(
      days,
      style: appProvider.dateFormatStyle == DateFormatStyle.days ? 'days' : 'combined',
    );
  }
  
  /// 获取过滤后的资产列表
  List<Asset> get _filteredAssets {
    List<Asset> filtered;
    
    if (_currentCategory == 'all') {
      // 全部：展示所有资产
      filtered = List.from(_assets);
    } else if (_currentCategory == 'pinned') {
      filtered = _assets.where((a) => a.isPinned).toList();
    } else if (_currentCategory.startsWith('custom_')) {
      // 自定义分栏：根据 tags 过滤
      final tabName = _currentCategory.substring(7); // 移除 'custom_' 前缀
      filtered = _assets.where((a) => a.tags.contains(tabName)).toList();
    } else {
      filtered = _assets.where((a) => a.category == _currentCategory).toList();
    }
    
    filtered.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'name':
          result = a.assetName.compareTo(b.assetName);
          break;
        case 'purchase_date':
          result = a.purchaseDate.compareTo(b.purchaseDate);
          break;
        case 'price':
          result = a.purchasePrice.compareTo(b.purchasePrice);
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
        // 自定义分栏：移除 'custom_' 前缀后返回
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
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryLabel(_currentCategory)),
        centerTitle: true,
        elevation: 0,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 分栏菜单（原筛选按钮更名）
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
                  const PopupMenuItem(value: 'subscription', child: Text('限时资产')),
                ];
                // 动态添加自定义分栏
                if (_customTabs.isNotEmpty) {
                  items.add(const PopupMenuDivider());
                  for (final tab in _customTabs) {
                    items.add(PopupMenuItem(
                      value: 'custom_$tab',
                      child: Row(
                        children: [
                          const Icon(Icons.label_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(tab),
                        ],
                      ),
                    ));
                  }
                }
                return items;
              },
            ),
            // 排序菜单（从右侧移到左侧）
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
                      if (_sortBy == 'created_at') const Icon(Icons.check, size: 18),
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
                      if (_sortBy == 'purchase_date') const Icon(Icons.check, size: 18),
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
                      Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
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
          // 添加按钮
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAssetForm(),
            tooltip: '添加资产',
          ),
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              // 从设置页返回时，重新读取自定义分栏并刷新资产数据
              await _loadCustomTabs();
              await _loadAssets(isRefresh: true);
            },
            tooltip: '设置',
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
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 加载状态
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  // 错误状态
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
                            const SizedBox(height: 10),
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
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
                  // 空状态
                  else if (filteredAssets.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text(
                              _assets.isEmpty ? '暂无资产数据' : '当前分栏暂无资产',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _assets.isEmpty ? '点击右上角 + 添加您的第一个资产' : '切换其他分栏查看或添加新资产',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  // 资产列表
                  else
                    ...filteredAssets.map((asset) => _buildAssetCard(asset)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建资产卡片
  Widget _buildAssetCard(Asset asset) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      elevation: 1,
      color: asset.isSold ? Colors.grey.shade200 : null,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (asset.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.push_pin, size: 14, color: Colors.orange.shade700),
                            ),
                          Flexible(
                            child: Text(
                              asset.assetName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: asset.isSold ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 操作菜单
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showAssetForm(asset: asset);
                            break;
                          case 'pin':
                            _togglePinned(asset);
                            break;
                          case 'delete':
                            _deleteAsset(asset);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('编辑'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(asset.isPinned ? Icons.push_pin_outlined : Icons.push_pin, size: 18),
                              const SizedBox(width: 8),
                              Text(asset.isPinned ? '取消置顶' : '置顶'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('删除', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.attach_money,
                        label: '购入价格',
                        value: _formatCurrency(asset.purchasePrice),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.calendar_today,
                        label: '预计使用',
                        value: _formatDays(asset.expectedLifespanDays),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (asset.isSold) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.sell,
                          label: '卖出价格',
                          value: _formatCurrency(asset.soldPrice ?? 0),
                          valueColor: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.trending_up,
                          label: '实际日均',
                          value: _formatCurrency(asset.actualDailyCost),
                          valueColor: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.timelapse,
                          label: '使用天数',
                          value: _formatDays(asset.actualUsedDays),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: asset.soldProfitOrLoss >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          label: '盈亏',
                          value: _formatCurrency(asset.soldProfitOrLoss.abs()),
                          valueColor: asset.soldProfitOrLoss >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ] else if (asset.category == 'subscription') ...[
                  // 限时资产显示
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.trending_up,
                          label: '日均成本',
                          value: _formatCurrency(asset.dailyCost),
                          valueColor: const Color(0xFF2196F3),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.event_busy,
                          label: '到期日期',
                          value: asset.expireDate != null 
                              ? '${asset.expireDate!.year}-${asset.expireDate!.month.toString().padLeft(2, '0')}-${asset.expireDate!.day.toString().padLeft(2, '0')}'
                              : '未设置',
                          valueColor: (asset.expireDate != null && asset.expireDate!.isBefore(DateTime.now())) 
                              ? Colors.red 
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.trending_up,
                          label: '日均成本',
                          value: _formatCurrency(asset.dailyCost),
                          valueColor: const Color(0xFF2196F3),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.hourglass_empty,
                          label: '剩余天数',
                          value: _formatDays(asset.remainingDays),
                          valueColor: asset.isExpired ? Colors.red : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // 已出售印章
          if (asset.isSold)
            Positioned(
              right: 50,
              top: 16,
              child: Transform.rotate(
                angle: -0.3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.shade400, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '已出售',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建信息项
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 3),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 显示添加/编辑资产表单
  Future<void> _showAssetForm({Asset? asset}) async {
    final isEditing = asset != null;
    
    // 表单控制器
    final nameController = TextEditingController(text: asset?.assetName ?? '');
    final priceController = TextEditingController(text: asset?.purchasePrice.toString() ?? '');
    final expectedDaysController = TextEditingController(text: asset?.expectedLifespanDays.toString() ?? '');
    
    // 日期控制器
    final purchaseDateController = TextEditingController(
      text: asset != null 
          ? '${asset.purchaseDate.year}-${asset.purchaseDate.month.toString().padLeft(2, '0')}-${asset.purchaseDate.day.toString().padLeft(2, '0')}'
          : '',
    );
    final soldDateController = TextEditingController(
      text: asset?.soldDate != null 
          ? '${asset!.soldDate!.year}-${asset.soldDate!.month.toString().padLeft(2, '0')}-${asset.soldDate!.day.toString().padLeft(2, '0')}'
          : '',
    );
    
    // 表单状态
    String category = asset?.category ?? 'physical';
    DateTime purchaseDate = asset?.purchaseDate ?? DateTime.now();
    bool isPinned = asset?.isPinned ?? false;
    bool isSold = asset?.isSold ?? false;
    double? soldPrice = asset?.soldPrice;
    DateTime? soldDate = asset?.soldDate;
    DateTime? expireDate = asset?.expireDate;
    List<String> selectedTags = asset?.tags.toList() ?? [];
    List<Map<String, dynamic>> renewalHistory = 
        (asset?.renewalHistory as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? '编辑资产' : '添加资产',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 资产类型选择器（编辑模式下不可修改）
                  if (!isEditing) ...[
                    const Text('资产类型', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'physical', label: Text('实体'), icon: Icon(Icons.inventory_2)),
                        ButtonSegment(value: 'virtual', label: Text('虚拟'), icon: Icon(Icons.cloud)),
                        ButtonSegment(value: 'subscription', label: Text('限时'), icon: Icon(Icons.timer)),
                      ],
                      selected: {category},
                      onSelectionChanged: (Set<String> selection) {
                        setModalState(() {
                          category = selection.first;
                          // 切换类型时重置一些状态
                          if (category == 'subscription') {
                            isSold = false;
                            soldPrice = null;
                            soldDate = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 资产名称
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '资产名称',
                      hintText: '例如：Mac Mini M4',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 购入价格
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: '购入价格',
                      hintText: '例如：4499',
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: '¥ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  
                  // 预计使用时长
                  TextFormField(
                    controller: expectedDaysController,
                    decoration: const InputDecoration(
                      labelText: '预计使用时长',
                      hintText: '例如：5 年、1 年 6 个月、1825 天',
                      prefixIcon: Icon(Icons.timelapse),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 购买日期
                  TextFormField(
                    controller: purchaseDateController,
                    decoration: const InputDecoration(
                      labelText: '购买日期',
                      hintText: '未填写默认当前日期',
                      prefixIcon: Icon(Icons.event),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // 支持手动输入日期解析
                      final parsed = Asset.parseCustomDate(value);
                      if (parsed != null) {
                        purchaseDate = parsed;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // 标签选择器（仅当有自定义分栏时显示）
                  if (_customTabs.isNotEmpty) ...[
                    const Text('自定义标签', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _customTabs.map((tab) {
                        final isSelected = selectedTags.contains(tab);
                        return FilterChip(
                          label: Text(tab),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedTags.add(tab);
                              } else {
                                selectedTags.remove(tab);
                              }
                            });
                          },
                          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).primaryColor,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 是否置顶（所有资产类型都可置顶）
                  SwitchListTile(
                    title: const Text('是否置顶'),
                    subtitle: const Text('置顶的资产会显示在首页置顶列表'),
                    value: isPinned,
                    onChanged: (value) {
                      setModalState(() => isPinned = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // 实体/虚拟资产特有字段
                  if (category != 'subscription') ...[
                    // 是否已出售（编辑模式下显示）
                    if (isEditing) ...[
                      SwitchListTile(
                        title: const Text('是否已出售'),
                        value: isSold,
                        onChanged: (value) {
                          setModalState(() => isSold = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // 已出售的额外字段
                      if (isSold) ...[
                        TextFormField(
                          initialValue: soldPrice?.toString() ?? '',
                          decoration: const InputDecoration(
                            labelText: '卖出价格',
                            prefixIcon: Icon(Icons.sell),
                            prefixText: '¥ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            soldPrice = double.tryParse(value);
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        TextFormField(
                          controller: soldDateController,
                          decoration: const InputDecoration(
                            labelText: '出售日期',
                            hintText: '未填写默认当前日期',
                            prefixIcon: Icon(Icons.event_available),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            // 支持手动输入日期解析
                            final parsed = Asset.parseCustomDate(value);
                            if (parsed != null) {
                              soldDate = parsed;
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ],
                  
                  // 限时资产特有字段
                  if (category == 'subscription') ...[
                    // 到期日期自动计算提示
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              expireDate != null
                                  ? '到期日期将自动计算：${expireDate!.year}-${expireDate!.month.toString().padLeft(2, '0')}-${expireDate!.day.toString().padLeft(2, '0')}'
                                  : '到期日期将根据购买日期和使用时长自动计算',
                              style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 续费记录
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('续费记录', style: TextStyle(fontWeight: FontWeight.w500)),
                                TextButton.icon(
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('新增'),
                                  onPressed: () => _showAddRenewalDialog(
                                    context, 
                                    renewalHistory, 
                                    expireDate,
                                    (newHistory, newExpireDate) {
                                      setModalState(() {
                                        renewalHistory = newHistory;
                                        expireDate = newExpireDate;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (renewalHistory.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('暂无续费记录', style: TextStyle(color: Colors.grey)),
                              )
                            else
                              ...renewalHistory.map((record) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.replay, size: 20),
                                title: Text('¥${record['price']?.toString() ?? '0'}'),
                                subtitle: Text(
                                  '${record['date'] ?? ''} · +${record['days'] ?? 0} 天',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  onPressed: () {
                                    setModalState(() {
                                      renewalHistory.remove(record);
                                    });
                                  },
                                ),
                              )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        // 验证输入
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入资产名称'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        final price = double.tryParse(priceController.text);
                        if (price == null || price <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入有效的购入价格'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        final days = Asset.parseExpectedDays(expectedDaysController.text);
                        if (days <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入有效的预计使用时长'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        
                        Navigator.pop(context);
                        
                        // 保存数据
                        try {
                          final currentUser = Supabase.instance.client.auth.currentUser;
                          if (currentUser == null) return;
                          
                          // 计算限时资产的到期日期
                          DateTime? calculatedExpireDate = expireDate;
                          if (category == 'subscription') {
                            calculatedExpireDate = purchaseDate.add(Duration(days: days));
                          }
                          
                          final assetData = {
                            'user_id': currentUser.id,
                            'asset_name': nameController.text.trim(),
                            'purchase_price': price,
                            'expected_lifespan_days': days,
                            'purchase_date': purchaseDate.toIso8601String(),
                            'is_pinned': isPinned,
                            'is_sold': isSold,
                            'category': category,
                            if (soldPrice != null && isSold) 'sold_price': soldPrice,
                            if (soldDate != null && isSold) 'sold_date': soldDate!.toIso8601String(),
                            if (calculatedExpireDate != null) 'expire_date': calculatedExpireDate!.toIso8601String(),
                            'renewal_history': renewalHistory,
                            'tags': selectedTags,
                          };
                          
                          if (isEditing) {
                            await Supabase.instance.client
                                .from('assets')
                                .update(assetData)
                                .eq('id', asset!.id!);
                          } else {
                            await Supabase.instance.client
                                .from('assets')
                                .insert(assetData);
                          }
                          
                          await _loadAssets(isRefresh: true);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEditing ? '资产已更新' : '资产添加成功'),
                                backgroundColor: Colors.green,
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(isEditing ? '保存修改' : '添加资产'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
    /// 显示添加续费记录对话框
  void _showAddRenewalDialog(
    BuildContext context,
    List<Map<String, dynamic>> currentHistory,
    DateTime? currentExpireDate,
    Function(List<Map<String, dynamic>>, DateTime?) onUpdate,
  ) {
    final priceController = TextEditingController();
    final daysController = TextEditingController();
    final dateController = TextEditingController();
    DateTime renewalDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增续费记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: '续费金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: daysController,
              decoration: const InputDecoration(
                labelText: '续费时长',
                hintText: '例如：1 年、6 个月、365 天',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: '付费日期',
                hintText: '例如：2026-01-01、2026年1月1日',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final parsed = Asset.parseCustomDate(value);
                if (parsed != null) {
                  renewalDate = parsed;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              final days = Asset.parseExpectedDays(daysController.text);
              
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效的金额'), backgroundColor: Colors.red),
                );
                return;
              }
              if (days <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效的续费时长'), backgroundColor: Colors.red),
                );
                return;
              }
              
              final newRecord = {
                'date': '${renewalDate.year}-${renewalDate.month.toString().padLeft(2, '0')}-${renewalDate.day.toString().padLeft(2, '0')}',
                'price': price,
                'days': days,
              };
              
              // 计算新的到期日期：基于当前到期日期（或购买日期）+ 续费时长
              DateTime newExpireDate;
              if (currentExpireDate != null && currentExpireDate.isAfter(DateTime.now())) {
                // 如果当前到期日期还未过期，从到期日期开始计算
                newExpireDate = currentExpireDate.add(Duration(days: days));
              } else {
                // 否则从续费日期开始计算
                newExpireDate = renewalDate.add(Duration(days: days));
              }
              
              final newHistory = [...currentHistory, newRecord];
              
              Navigator.pop(context);
              onUpdate(newHistory, newExpireDate);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asset.dart';
import '../providers/app_provider.dart';

/// 首页 - 添加资产页面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // 表单控制器
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _expectedDaysController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  
  // 购买日期
  DateTime _purchaseDate = DateTime.now();
  
  // 资产列表
  List<Asset> _assets = [];
  bool _isLoading = true;       // 首次加载
  bool _isRefreshing = false;   // 刷新中（不影响已有数据展示）
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _updatePurchaseDateText();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _expectedDaysController.dispose();
    _purchaseDateController.dispose();
    super.dispose();
  }

  /// 更新购买日期文本
  void _updatePurchaseDateText() {
    _purchaseDateController.text = '${_purchaseDate.year}-${_purchaseDate.month.toString().padLeft(2, '0')}-${_purchaseDate.day.toString().padLeft(2, '0')}';
  }

  /// 从 Supabase 加载资产数据
  /// [isRefresh] 为 true 时表示下拉刷新，不清空已有数据，实现无缝刷新
  Future<void> _loadAssets({bool isRefresh = false}) async {
    // 如果是刷新操作且已有数据，只显示刷新状态，不清空列表
    if (isRefresh && _assets.isNotEmpty) {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    } else {
      // 首次加载或无数据时，显示全屏加载
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // 排序：is_pinned DESC, created_at DESC（置顶优先，其余按创建时间倒序）
      final response = await Supabase.instance.client
          .from('assets')
          .select()
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      // 更新云端同步时间
      if (response.isNotEmpty) {
        final latestAsset = Asset.fromJson(response.first);
        if (mounted) {
          context.read<AppProvider>().updateSyncTime(latestAsset.createdAt);
        }
      }

      setState(() {
        _assets = (response as List).map((item) => Asset.fromJson(item)).toList();
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        // 只在首次加载或无数据时设置错误信息
        if (_assets.isEmpty) {
          _errorMessage = '加载数据失败：$e';
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载数据失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 添加资产到 Supabase
  Future<void> _addAsset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 调用 save() 触发 onSaved 回调，更新 _purchaseDate
    _formKey.currentState!.save();

    // 解析预计使用天数（支持自然语言）
    final lifespanInput = _expectedDaysController.text.trim();
    final parsedDays = DateParser.parseLifespan(lifespanInput);
    if (parsedDays == null || parsedDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入有效的预计使用天数'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 创建新资产对象
      final newAsset = Asset(
        assetName: _nameController.text.trim(),
        purchasePrice: double.parse(_priceController.text),
        expectedLifespanDays: parsedDays,
        purchaseDate: _purchaseDate,
      );

      // 插入到 Supabase
      await Supabase.instance.client.from('assets').insert(newAsset.toJson());

      // 关闭加载指示器
      if (mounted) Navigator.of(context).pop();

      // 刷新列表
      await _loadAssets();

      // 清空表单
      _nameController.clear();
      _priceController.clear();
      _expectedDaysController.clear();
      setState(() {
        _purchaseDate = DateTime.now();
        _updatePurchaseDateText();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('资产添加成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 关闭加载指示器
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加失败：$e'),
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
      
      await _loadAssets();
      
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
        
        await _loadAssets();
        
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

  /// 编辑资产
  Future<void> _editAsset(Asset asset) async {
    // 控制器初始化
    final nameController = TextEditingController(text: asset.assetName);
    final priceController = TextEditingController(text: asset.purchasePrice.toString());
    final expectedDaysController = TextEditingController(text: asset.expectedLifespanDays.toString());
    final purchaseDateController = TextEditingController(
      text: '${asset.purchaseDate.year}.${asset.purchaseDate.month}.${asset.purchaseDate.day}',
    );
    DateTime purchaseDate = asset.purchaseDate;
    String? expectedDaysError;
    String? purchaseDateError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑资产'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '资产名称',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: '购入价格',
                    prefixText: '¥ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: expectedDaysController,
                  decoration: InputDecoration(
                    labelText: '预计使用时长',
                    hintText: '例如：5 年、1 年 6 个月、1825 天',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    errorText: expectedDaysError,
                  ),
                  onChanged: (value) {
                    final parsed = Asset.parseExpectedDays(value);
                    setDialogState(() {
                      expectedDaysError = parsed > 0 ? null : '请输入有效的预计使用时长';
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: purchaseDateController,
                  decoration: InputDecoration(
                    labelText: '购买日期',
                    hintText: '例如：2026.4.5 或 2026年1月1日',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    errorText: purchaseDateError,
                  ),
                  onChanged: (value) {
                    final parsed = Asset.parseCustomDate(value.trim());
                    setDialogState(() {
                      if (parsed != null) {
                        purchaseDate = parsed;
                        purchaseDateError = null;
                      } else {
                        purchaseDateError = '日期格式错误，请使用如 2026-1-1、2026.1.1 或 2026年1月1日 格式';
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                // 验证输入
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入资产名称'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final price = double.tryParse(priceController.text);
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入有效的购入价格'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final days = Asset.parseExpectedDays(expectedDaysController.text);
                if (days <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入有效的预计使用时长'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final parsedDate = Asset.parseCustomDate(purchaseDateController.text);
                if (parsedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入有效的购买日期'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('保存修改'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final parsedDays = Asset.parseExpectedDays(expectedDaysController.text);
        final parsedDate = Asset.parseCustomDate(purchaseDateController.text) ?? purchaseDate;
        final updatedAsset = asset.copyWith(
          assetName: nameController.text.trim(),
          purchasePrice: double.parse(priceController.text),
          expectedLifespanDays: parsedDays,
          purchaseDate: parsedDate,
        );

        await Supabase.instance.client
            .from('assets')
            .update(updatedAsset.toJson())
            .eq('id', asset.id!);
        
        await _loadAssets();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('资产已更新'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('更新失败：$e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 出售资产
  Future<void> _sellAsset(Asset asset) async {
    final soldPriceController = TextEditingController();
    DateTime soldDate = DateTime.now();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('出售资产'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('资产：${asset.assetName}'),
              Text('原购入价：¥${asset.purchasePrice.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              TextField(
                controller: soldPriceController,
                decoration: const InputDecoration(
                  labelText: '卖出价格',
                  prefixText: '¥ ',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: soldDate,
                    firstDate: asset.purchaseDate,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => soldDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '出售日期',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    '${soldDate.year}-${soldDate.month.toString().padLeft(2, '0')}-${soldDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final price = double.tryParse(soldPriceController.text);
                if (price == null || price < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入有效的卖出价格'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('确认出售'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('assets')
            .update({
              'is_sold': true,
              'sold_price': double.parse(soldPriceController.text),
              'sold_date': soldDate.toIso8601String(),
            })
            .eq('id', asset.id!);
        
        await _loadAssets();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('资产已标记为出售'),
              backgroundColor: Colors.green,
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
  }

  /// 格式化金额
  String _formatCurrency(double amount) {
    return '¥${amount.toStringAsFixed(2)}';
  }

  /// 格式化天数（根据设置）
  String _formatDays(int days) {
    final appProvider = context.watch<AppProvider>();
    return DateParser.formatDays(
      days,
      style: appProvider.dateFormatStyle == DateFormatStyle.days ? 'days' : 'combined',
    );
  }

  /// 退出登录
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已退出登录'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('退出失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资产管理'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssets,
            tooltip: '刷新数据',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: '设置',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: '退出登录',
          ),
        ],
      ),
      // Web 端宽度限制：在宽屏上限制最大宽度为 600，居中显示
      body: Stack(
        children: [
          // 主体内容
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 添加资产表单卡片
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '添加资产',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 资产名称输入框
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: '资产名称',
                                  hintText: '例如：Mac Mini M4',
                                  prefixIcon: Icon(Icons.inventory_2_outlined),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '请输入资产名称';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              // 价格输入框
                              TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  labelText: '购入价格',
                                  hintText: '例如：4499',
                                  prefixIcon: Icon(Icons.attach_money),
                                  prefixText: '¥ ',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '请输入价格';
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null || price <= 0) {
                                    return '请输入有效的价格';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              // 预计使用天数输入框（支持自然语言）
                              TextFormField(
                                controller: _expectedDaysController,
                                decoration: const InputDecoration(
                                  labelText: '预计使用时长',
                                  hintText: '例如：5 年、1 年 6 个月、1825 天',
                                  prefixIcon: Icon(Icons.timelapse),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '请输入预计使用时长';
                                  }
                                  final days = Asset.parseExpectedDays(value);
                                  if (days <= 0) {
                                    return '请输入有效的预计使用时长';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              // 购买日期输入框（支持手写输入）
                              TextFormField(
                                controller: _purchaseDateController,
                                decoration: const InputDecoration(
                                  labelText: '购买日期',
                                  hintText: '例如：2026.4.5 或 2026年1月1日',
                                  prefixIcon: Icon(Icons.event),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '请输入购买日期';
                                  }
                                  final parsed = Asset.parseCustomDate(value.trim());
                                  if (parsed == null) {
                                    return '日期格式错误，请使用如 2026-1-1、2026.1.1 或 2026年1月1日 格式';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  // validator 已经验证过，这里直接解析赋值
                                  // 如果解析失败，不允许静默通过，应该抛出异常
                                  final parsed = Asset.parseCustomDate(value?.trim() ?? '');
                                  if (parsed == null) {
                                    throw StateError('日期解析失败，这不应该发生，因为 validator 已经验证过了');
                                  }
                                  _purchaseDate = parsed;
                                },
                              ),
                              const SizedBox(height: 12),
                              // 添加按钮
                              SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: _addAsset,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '添加资产',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 资产列表标题
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '资产列表',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '共 ${_assets.length} 项',
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
                    else if (_assets.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              Text(
                                '暂无资产数据',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '点击上方表单添加您的第一个资产',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    // 资产列表
                    else
                      ..._assets.map((asset) => _buildAssetCard(asset)),
                  ],
                ),
              ),
            ),
          ),
          // 顶部刷新进度条（仅在刷新时显示）
          if (_isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
        ],
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
                            _editAsset(asset);
                            break;
                          case 'pin':
                            _togglePinned(asset);
                            break;
                          case 'sell':
                            _sellAsset(asset);
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
                        if (!asset.isSold)
                          const PopupMenuItem(
                            value: 'sell',
                            child: Row(
                              children: [
                                Icon(Icons.sell, size: 18),
                                SizedBox(width: 8),
                                Text('出售'),
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
                  // 已出售显示
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
                ] else ...[
                  // 未出售显示
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
}
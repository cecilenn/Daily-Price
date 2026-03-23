import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../services/local_db_service.dart';
import '../utils/image_utils.dart';
import '../widgets/smart_asset_avatar.dart';
import '../widgets/avatar_editor_sheet.dart';

/// 添加/编辑资产全屏页面 - V2.0 重构版
class AddEditAssetScreen extends StatefulWidget {
  final Asset? existingAsset;

  const AddEditAssetScreen({super.key, this.existingAsset});

  @override
  State<AddEditAssetScreen> createState() => _AddEditAssetScreenState();
}

class _AddEditAssetScreenState extends State<AddEditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool isEditing;
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController expectedDaysController;
  late TextEditingController purchaseDateController;
  late TextEditingController soldDateController;

  late String category;
  late int purchaseDate;
  late int isPinned;
  late int status;
  late double? soldPrice;
  late int? soldDate;
  late int? expireDate;
  late List<String> selectedTags;
  late int excludeFromTotal;
  late int excludeFromDaily;
  late String? avatarPath;
  late int? avatarBgColor;
  late String? avatarText;
  late int? avatarIconCodePoint;
  late String _ownershipType;
  late List<RenewalRecord> _renewals;
  List<String> _customTabs = [];
  List<String> _customCategories = ['未分类'];
  bool _isSaving = false;

  // 用于存储临时编辑状态的头像数据
  AvatarEditResult? _tempAvatarResult;

  @override
  void initState() {
    super.initState();
    isEditing = widget.existingAsset != null;
    nameController = TextEditingController(
      text: widget.existingAsset?.assetName ?? '',
    );
    priceController = TextEditingController(
      text: widget.existingAsset?.purchasePrice?.toString() ?? '',
    );
    expectedDaysController = TextEditingController(
      text: widget.existingAsset?.expectedLifespanDays?.toString() ?? '',
    );
    purchaseDateController = TextEditingController(
      text: widget.existingAsset != null
          ? _formatDateFromTimestamp(widget.existingAsset!.purchaseDate)
          : '',
    );
    soldDateController = TextEditingController(
      text: widget.existingAsset?.soldDate != null
          ? _formatDateFromTimestamp(widget.existingAsset!.soldDate!)
          : '',
    );

    category = widget.existingAsset?.category ?? '未分类';
    purchaseDate =
        widget.existingAsset?.purchaseDate ??
        DateTime.now().millisecondsSinceEpoch;
    isPinned = widget.existingAsset?.isPinned ?? 0;
    status = widget.existingAsset?.status ?? 0;
    soldPrice = widget.existingAsset?.soldPrice;
    soldDate = widget.existingAsset?.soldDate;
    expireDate = widget.existingAsset?.expireDate;
    selectedTags = widget.existingAsset?.tags.toList() ?? [];
    excludeFromTotal = widget.existingAsset?.excludeFromTotal ?? 0;
    excludeFromDaily = widget.existingAsset?.excludeFromDaily ?? 0;
    avatarPath = widget.existingAsset?.avatarPath;
    avatarBgColor = widget.existingAsset?.avatarBgColor;
    avatarText = widget.existingAsset?.avatarText;
    avatarIconCodePoint = widget.existingAsset?.avatarIconCodePoint;
    _ownershipType = widget.existingAsset?.ownershipType ?? 'buyout';
    _renewals = widget.existingAsset?.renewals.toList() ?? [];

    _loadCustomTabs();
    _loadCustomCategories();
  }

  Future<void> _loadCustomTabs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customTabs = prefs.getStringList('custom_tabs') ?? [];
    });
  }

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customCategories = prefs.getStringList('custom_categories') ?? ['未分类'];
    });
  }

  String _formatDateFromTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑资产' : '添加资产'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveAsset,
              child: const Text(
                '保存',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像编辑区域 - V3.0 复合头像引擎
              Center(
                child: GestureDetector(
                  onTap: _showAvatarEditor,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _buildAvatarWidget(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 资产名称
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '资产名称 *',
                  hintText: '例如：Mac Mini M4',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入资产名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 购入价格
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: '购入价格 *',
                  hintText: '例如：4499',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '¥ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final price = double.tryParse(value ?? '');
                  if (price == null || price <= 0) {
                    return '请输入有效的购入价格';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 预计使用时长
              TextFormField(
                controller: expectedDaysController,
                decoration: const InputDecoration(
                  labelText: '预计使用时长（可选）',
                  hintText: '例如：5 年、1 年 6 个月、1825 天',
                  prefixIcon: Icon(Icons.timelapse),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
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
                  final parsed = Asset.parseCustomDate(value);
                  if (parsed != null) {
                    purchaseDate = parsed.millisecondsSinceEpoch;
                  }
                },
              ),
              const SizedBox(height: 20),
              // 资产状态
              const Text(
                '资产状态',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: status,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('🟢 服役中')),
                  DropdownMenuItem(value: 1, child: Text('⚫ 已退役')),
                  DropdownMenuItem(value: 2, child: Text('💰 已卖出')),
                ],
                onChanged: (value) {
                  setState(() {
                    status = value!;
                    if (status != 2) soldPrice = null;
                    if (status == 0) soldDate = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              // 卖出价格
              if (status == 2) ...[
                TextFormField(
                  initialValue: soldPrice?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: '卖出价格',
                    prefixIcon: Icon(Icons.sell),
                    prefixText: '¥ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    soldPrice = double.tryParse(value);
                  },
                ),
                const SizedBox(height: 16),
              ],
              // 卖出/退役日期
              if (status == 1 || status == 2) ...[
                TextFormField(
                  controller: soldDateController,
                  decoration: InputDecoration(
                    labelText: status == 2 ? '卖出日期' : '退役日期',
                    hintText: '未填写默认当前日期',
                    prefixIcon: Icon(Icons.event_available),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final parsed = Asset.parseCustomDate(value);
                    if (parsed != null) {
                      soldDate = parsed.millisecondsSinceEpoch;
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
              // 资产分类
              const Text(
                '资产分类',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _customCategories.contains(category)
                    ? category
                    : '未分类',
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: _customCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    category = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // 所有权类型
              const Text(
                '所有权类型',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _ownershipType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'buyout', child: Text('买断')),
                  DropdownMenuItem(value: 'subscription', child: Text('订阅')),
                ],
                onChanged: (value) {
                  setState(() {
                    _ownershipType = value ?? 'buyout';
                    // 如果从订阅切换到买断，清除到期日期
                    if (_ownershipType == 'buyout') {
                      expireDate = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              // 续费记录管理（仅订阅类型显示）
              if (_ownershipType == 'subscription') ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '续费记录（${_renewals.length} 条）',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('添加续费'),
                      onPressed: _addRenewal,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_renewals.isEmpty)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '暂无续费记录',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ..._renewals.map((renewal) => _buildRenewalCard(renewal)),
              ],
              // 标签选择器
              if (_customTabs.isNotEmpty) ...[
                const Text(
                  '自定义标签',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _customTabs.map((tab) {
                    final tagValue = 'custom_$tab';
                    final isSelected = selectedTags.contains(tagValue);
                    return FilterChip(
                      label: Text(tab),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedTags.add(tagValue);
                          } else {
                            selectedTags.remove(tagValue);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
              // 置顶开关
              SwitchListTile(
                title: const Text('是否置顶'),
                subtitle: const Text('置顶的资产会显示在首页置顶列表'),
                value: isPinned == 1,
                onChanged: (value) => setState(() => isPinned = value ? 1 : 0),
              ),
              // 排除选项
              SwitchListTile(
                title: const Text('不计入总资产'),
                subtitle: const Text('该资产将不参与总资产计算'),
                value: excludeFromTotal == 1,
                onChanged: (value) =>
                    setState(() => excludeFromTotal = value ? 1 : 0),
              ),
              SwitchListTile(
                title: const Text('不计入日均消费'),
                subtitle: const Text('该资产将不参与日均消费计算'),
                value: excludeFromDaily == 1,
                onChanged: (value) =>
                    setState(() => excludeFromDaily = value ? 1 : 0),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建头像组件
  Widget _buildAvatarWidget() {
    // 构建一个临时 Asset 对象用于 SmartAssetAvatar
    final tempAsset = Asset.create(
      id: widget.existingAsset?.id ?? '',
      assetName: nameController.text.isNotEmpty
          ? nameController.text
          : (widget.existingAsset?.assetName ?? ''),
      purchaseDate: purchaseDate,
      avatarPath: avatarPath,
      avatarBgColor: avatarBgColor,
      avatarText: avatarText,
      avatarIconCodePoint: avatarIconCodePoint,
    );

    return SmartAssetAvatar(
      asset: tempAsset,
      radius: 60,
      defaultBgColor: const Color(0xFFE0E0E0),
    );
  }

  /// 显示头像编辑器底部面板
  Future<void> _showAvatarEditor() async {
    // 构建当前状态的 Asset 对象
    final currentAsset = Asset.create(
      id: widget.existingAsset?.id ?? '',
      assetName: nameController.text.isNotEmpty
          ? nameController.text
          : (widget.existingAsset?.assetName ?? ''),
      purchaseDate: purchaseDate,
      avatarPath: avatarPath,
      avatarBgColor: avatarBgColor,
      avatarText: avatarText,
      avatarIconCodePoint: avatarIconCodePoint,
    );

    final result = await showModalBottomSheet<AvatarEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarEditorSheet(
        initialAsset: currentAsset,
        onAvatarChanged: (avatarData) {
          // 实时更新状态（可选，当前使用确定后再更新）
        },
      ),
    );

    if (result != null) {
      setState(() {
        avatarPath = result.avatarPath;
        avatarBgColor = result.avatarBgColor;
        avatarText = result.avatarText;
        avatarIconCodePoint = result.avatarIconCodePoint;
      });
    }
  }

  Widget _buildRenewalCard(RenewalRecord renewal) {
    final dateStr = _formatDateFromTimestamp(renewal.renewalDate);
    final expireStr = _formatDateFromTimestamp(renewal.expireDate);

    // 计算时长显示
    String durationText;
    final d = renewal.durationDays;
    if (d >= 365)
      durationText = '${(d / 365).toStringAsFixed(1)}年';
    else if (d >= 30)
      durationText = '${(d / 30).round()}月';
    else
      durationText = '${d}天';

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '$dateStr  ¥${renewal.price.toStringAsFixed(0)}/$durationText',
        ),
        subtitle: Text('到期：$expireStr'),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            setState(() {
              _renewals.removeWhere((r) => r.id == renewal.id);
            });
          },
        ),
      ),
    );
  }

  Future<void> _addRenewal() async {
    final dateController = TextEditingController(
      text: _formatDateFromTimestamp(DateTime.now().millisecondsSinceEpoch),
    );
    final priceController = TextEditingController();
    int selectedUnit = 0; // 0=年, 1=月, 2=天
    final durationController = TextEditingController(text: '1');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('添加续费记录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: '续费日期',
                  hintText: '默认今天',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: '续费金额',
                  prefixText: '¥ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      decoration: InputDecoration(
                        labelText: '时长',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 8),
                  DropdownButton<int>(
                    value: selectedUnit,
                    items: [
                      DropdownMenuItem(value: 0, child: Text('年')),
                      DropdownMenuItem(value: 1, child: Text('月')),
                      DropdownMenuItem(value: 2, child: Text('天')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedUnit = v ?? 0),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final price = double.tryParse(priceController.text) ?? 0;
      final duration = int.tryParse(durationController.text) ?? 1;
      int days;
      switch (selectedUnit) {
        case 0:
          days = (duration * 365.25).round();
          break;
        case 1:
          days = (duration * 30.44).round();
          break;
        default:
          days = duration;
      }

      int renewalDate = DateTime.now().millisecondsSinceEpoch;
      final parsed = Asset.parseCustomDate(dateController.text);
      if (parsed != null) renewalDate = parsed.millisecondsSinceEpoch;

      // 顺沿逻辑：如果续费日仍在上一次续费期限内，从到期日开始算
      int effectiveDate = renewalDate;
      if (_renewals.isNotEmpty) {
        final lastExpire = _renewals.last.expireDate;
        if (renewalDate < lastExpire) {
          effectiveDate = lastExpire; // 顺沿
        }
      }

      setState(() {
        _renewals.add(
          RenewalRecord(
            id: const Uuid().v4(),
            renewalDate: effectiveDate,
            price: price,
            durationDays: days,
          ),
        );
        // 按日期排序
        _renewals.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
      });
    }
  }

  Future<void> _saveAsset() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

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

    int? expectedDays;
    if (expectedDaysController.text.trim().isNotEmpty) {
      expectedDays = Asset.parseExpectedDays(expectedDaysController.text);
      if (expectedDays <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请输入有效的预计使用时长'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      int? calculatedExpireDate = expireDate;
      if (category == 'subscription' && expectedDays != null) {
        calculatedExpireDate =
            purchaseDate + Duration(days: expectedDays).inMilliseconds;
      }

      final newAsset = Asset.create(
        id: widget.existingAsset?.id,
        assetName: nameController.text.trim(),
        purchasePrice: price,
        expectedLifespanDays: expectedDays,
        purchaseDate: purchaseDate,
        isPinned: isPinned,
        status: status,
        soldPrice: status == 2 ? soldPrice : null,
        soldDate: status == 1 || status == 2 ? soldDate : null,
        category: category,
        ownershipType: _ownershipType,
        expireDate: calculatedExpireDate,
        renewals: _renewals,
        tags: selectedTags,
        excludeFromTotal: excludeFromTotal,
        excludeFromDaily: excludeFromDaily,
        avatarPath: avatarPath,
        avatarBgColor: avatarBgColor,
        avatarText: avatarText,
        avatarIconCodePoint: avatarIconCodePoint,
      );

      await context.read<AssetProvider>().saveAsset(newAsset);

      if (mounted) {
        Navigator.pop(context, true); // 返回成功标志
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    expectedDaysController.dispose();
    purchaseDateController.dispose();
    soldDateController.dispose();
    super.dispose();
  }
}

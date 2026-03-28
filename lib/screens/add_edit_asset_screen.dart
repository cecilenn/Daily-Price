import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../widgets/smart_asset_avatar.dart';
import '../widgets/avatar_editor_sheet.dart';
import '../widgets/date_text_field.dart';

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
  late List<ConsumableRecord> _consumables;
  List<ReplacementRecord> _replacements = [];
  bool _showConsumables = false;
  List<String> _customTabs = [];
  List<String> _customCategories = ['未分类'];
  bool _isSaving = false;

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
    _consumables = widget.existingAsset?.consumables.toList() ?? [];
    _replacements = List.from(widget.existingAsset?.replacements ?? []);
    _showConsumables = _consumables.isNotEmpty;

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

  DateTime? _parseDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}
    return null;
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
              DateTextField(
                labelText: '购买日期',
                initialDate: widget.existingAsset != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        widget.existingAsset!.purchaseDate,
                      )
                    : null,
                onDateChanged: (date) {
                  if (date != null) purchaseDate = date.millisecondsSinceEpoch;
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
                DateTextField(
                  labelText: status == 2 ? '卖出日期' : '退役日期',
                  initialDate: widget.existingAsset?.soldDate != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                          widget.existingAsset!.soldDate!,
                        )
                      : null,
                  onDateChanged: (date) {
                    soldDate = date?.millisecondsSinceEpoch;
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
              // 耗材管理
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text(
                  '耗材管理',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _showConsumables ? '${_consumables.length} 个耗材' : '关闭',
                ),
                secondary: const Icon(Icons.inventory_2_outlined),
                value: _showConsumables,
                onChanged: (value) {
                  setState(() {
                    _showConsumables = value;
                    if (!value) _consumables.clear();
                  });
                },
              ),

              // 耗材列表和添加按钮（仅在开启时显示）
              if (_showConsumables) ...[
                const SizedBox(height: 8),
                ..._consumables.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  // 该耗材的更换记录（按日期倒序）
                  final records =
                      _replacements
                          .where((r) => r.consumableName == c.name)
                          .toList()
                        ..sort((a, b) => b.replacedAt.compareTo(a.replacedAt));

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      title: Text(c.name),
                      subtitle: Text(
                        c.price > 0
                            ? '¥${c.price.toStringAsFixed(0)} / ${c.cycleDays}天 · 日均¥${c.dailyCost.toStringAsFixed(1)}'
                            : '${c.cycleDays}天',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showEditConsumableDialog(i),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                            onPressed: () => setState(() {
                              _consumables.removeAt(i);
                              // 同时删除该耗材的所有更换记录
                              _replacements.removeWhere(
                                (r) => r.consumableName == c.name,
                              );
                            }),
                          ),
                        ],
                      ),
                      children: [
                        // 购买日期
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '购买日期：${_formatDateFromTimestamp(c.purchasedAt)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        // 更换记录
                        if (records.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '暂无更换记录',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ...records.map(
                            (r) => ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(
                                left: 32,
                                right: 8,
                              ),
                              leading: const Icon(Icons.history, size: 18),
                              title: Text(
                                _formatDateFromTimestamp(r.replacedAt),
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                '¥${r.price.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    onPressed: () =>
                                        _showEditReplacementDialog(c, r),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => setState(() {
                                      _replacements.removeWhere(
                                        (rr) => rr.id == r.id,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // 添加更换记录按钮
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                '添加更换记录',
                                style: TextStyle(fontSize: 13),
                              ),
                              onPressed: () => _showAddReplacementDialog(c),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('添加耗材'),
                    onPressed: _showAddConsumableDialog,
                  ),
                ),
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
    final priceController = TextEditingController();
    final durationController = TextEditingController(text: '1');
    DateTime? selectedRenewalDate;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加续费记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DateTextField(
              labelText: '续费日期',
              initialDate: null,
              onDateChanged: (date) {
                selectedRenewalDate = date;
              },
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
            TextField(
              controller: durationController,
              decoration: InputDecoration(
                labelText: '时长',
                hintText: '1年、6个月、365天',
                border: OutlineInputBorder(),
              ),
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
    );

    if (confirmed == true) {
      final price = double.tryParse(priceController.text) ?? 0;
      final days = Asset.parseExpectedDays(durationController.text);
      if (days <= 0) return; // 无效输入不添加

      int renewalDate =
          selectedRenewalDate?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;

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

  Future<void> _showAddConsumableDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final cycleController = TextEditingController();
    DateTime? selectedPurchaseDate;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加耗材'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '耗材名称',
                  hintText: 'PP棉滤芯',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '单价',
                  prefixText: '¥ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cycleController,
                decoration: const InputDecoration(
                  labelText: '更换周期',
                  hintText: '6个月、180天、1年',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DateTextField(
                labelText: '购买日期',
                initialDate: null,
                onDateChanged: (date) {
                  selectedPurchaseDate = date;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final name = nameController.text.trim();
      final price = double.tryParse(priceController.text);
      final cycleText = cycleController.text.trim();
      final cycle = cycleText.isNotEmpty
          ? Asset.parseExpectedDays(cycleText)
          : 0;
      final purchasedAt = selectedPurchaseDate ?? DateTime.now();
      if (name.isNotEmpty && cycle > 0) {
        setState(() {
          _consumables.add(
            ConsumableRecord(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              price: price ?? 0,
              cycleDays: cycle,
              purchasedAt: purchasedAt.millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        });
      }
    }
  }

  Future<void> _showEditConsumableDialog(int index) async {
    final c = _consumables[index];
    final nameController = TextEditingController(text: c.name);
    final priceController = TextEditingController(
      text: c.price.toStringAsFixed(0),
    );
    final cycleController = TextEditingController(text: c.cycleDays.toString());
    DateTime? selectedPurchaseDate;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑耗材'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '耗材名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '单价',
                  prefixText: '¥ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cycleController,
                decoration: const InputDecoration(
                  labelText: '更换周期',
                  hintText: '6个月、180天、1年',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DateTextField(
                labelText: '购买日期',
                initialDate: DateTime.fromMillisecondsSinceEpoch(c.purchasedAt),
                onDateChanged: (date) {
                  selectedPurchaseDate = date;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final name = nameController.text.trim();
      final price = double.tryParse(priceController.text);
      final cycleText = cycleController.text.trim();
      final cycle = cycleText.isNotEmpty
          ? Asset.parseExpectedDays(cycleText)
          : 0;
      final purchasedAt =
          selectedPurchaseDate ??
          DateTime.fromMillisecondsSinceEpoch(c.purchasedAt);
      if (name.isNotEmpty && cycle > 0) {
        setState(() {
          _consumables[index] = ConsumableRecord(
            id: c.id,
            name: name,
            price: price ?? 0,
            cycleDays: cycle,
            purchasedAt: purchasedAt.millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        });
      }
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
        consumables: _consumables,
        replacements: _replacements,
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

  Future<void> _showAddReplacementDialog(ConsumableRecord consumable) async {
    final priceController = TextEditingController(
      text: consumable.price.toStringAsFixed(0),
    );
    DateTime? selectedDate;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('更换 ${consumable.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DateTextField(
              labelText: '更换日期',
              initialDate: null,
              onDateChanged: (date) => selectedDate = date,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '花费金额',
                prefixText: '¥ ',
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
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final date = selectedDate ?? DateTime.now();
      setState(() {
        _replacements.add(
          ReplacementRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            consumableName: consumable.name,
            replacedAt: date.millisecondsSinceEpoch,
            price: double.tryParse(priceController.text) ?? consumable.price,
            note: null,
          ),
        );
      });
    }
  }

  Future<void> _showEditReplacementDialog(
    ConsumableRecord consumable,
    ReplacementRecord record,
  ) async {
    final priceController = TextEditingController(
      text: record.price.toStringAsFixed(0),
    );
    DateTime? selectedDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑更换记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DateTextField(
              labelText: '更换日期',
              initialDate: DateTime.fromMillisecondsSinceEpoch(
                record.replacedAt,
              ),
              onDateChanged: (date) => selectedDate = date,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '花费金额',
                prefixText: '¥ ',
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
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final date =
          selectedDate ??
          DateTime.fromMillisecondsSinceEpoch(record.replacedAt);
      setState(() {
        final idx = _replacements.indexWhere((r) => r.id == record.id);
        if (idx >= 0) {
          _replacements[idx] = ReplacementRecord(
            id: record.id,
            consumableName: record.consumableName,
            replacedAt: date.millisecondsSinceEpoch,
            price: double.tryParse(priceController.text) ?? record.price,
            note: record.note,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    expectedDaysController.dispose();
    super.dispose();
  }
}

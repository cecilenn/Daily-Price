import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
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
  List<String> _customTabs = [];
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

    category = widget.existingAsset?.category ?? 'physical';
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

    _loadCustomTabs();
  }

  Future<void> _loadCustomTabs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customTabs = prefs.getStringList('custom_tabs') ?? [];
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
        expireDate: calculatedExpireDate,
        tags: selectedTags,
        excludeFromTotal: excludeFromTotal,
        excludeFromDaily: excludeFromDaily,
        avatarPath: avatarPath,
        avatarBgColor: avatarBgColor,
        avatarText: avatarText,
        avatarIconCodePoint: avatarIconCodePoint,
      );

      await LocalDbService().saveAsset(newAsset);

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

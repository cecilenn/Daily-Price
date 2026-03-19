import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '../services/local_db_service.dart';
import '../utils/image_utils.dart';

/// 资产编辑对话框 - 可复用于 HomeScreen 和 AssetDetailScreen
class AssetFormDialog extends StatefulWidget {
  final Asset? asset;

  const AssetFormDialog({super.key, this.asset});

  @override
  State<AssetFormDialog> createState() => _AssetFormDialogState();
}

class _AssetFormDialogState extends State<AssetFormDialog> {
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
  List<String> _customTabs = [];

  @override
  void initState() {
    super.initState();
    isEditing = widget.asset != null;
    nameController = TextEditingController(text: widget.asset?.assetName ?? '');
    priceController = TextEditingController(
      text: widget.asset?.purchasePrice?.toString() ?? '',
    );
    expectedDaysController = TextEditingController(
      text: widget.asset?.expectedLifespanDays?.toString() ?? '',
    );
    purchaseDateController = TextEditingController(
      text: widget.asset != null && widget.asset!.purchaseDate != null
          ? _formatDateFromTimestamp(widget.asset!.purchaseDate)
          : '',
    );
    soldDateController = TextEditingController(
      text: widget.asset?.soldDate != null
          ? _formatDateFromTimestamp(widget.asset!.soldDate!)
          : '',
    );

    category = widget.asset?.category ?? 'physical';
    purchaseDate =
        widget.asset?.purchaseDate ?? DateTime.now().millisecondsSinceEpoch;
    isPinned = widget.asset?.isPinned ?? 0;
    status = widget.asset?.status ?? 0;
    soldPrice = widget.asset?.soldPrice;
    soldDate = widget.asset?.soldDate;
    expireDate = widget.asset?.expireDate;
    selectedTags = widget.asset?.tags.toList() ?? [];
    excludeFromTotal = widget.asset?.excludeFromTotal ?? 0;
    excludeFromDaily = widget.asset?.excludeFromDaily ?? 0;
    avatarPath = widget.asset?.avatarPath;

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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            // 头像编辑区域
            Center(
              child: GestureDetector(
                onTap: () async {
                  final imagePath = await ImageUtils.pickAndCropImage();
                  if (imagePath != null) {
                    setState(() {
                      avatarPath = imagePath;
                    });
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: avatarPath != null && File(avatarPath!).existsSync()
                      ? ClipOval(
                          child: Image.file(
                            File(avatarPath!),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 32,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '添加头像',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
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
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
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
                      final parsed = Asset.parseCustomDate(value);
                      if (parsed != null) {
                        purchaseDate = parsed.millisecondsSinceEpoch;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // 资产状态
                  const Text(
                    '资产状态',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: status,
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
                        if (status != 2) {
                          soldPrice = null;
                        }
                        if (status == 0) {
                          soldDate = null;
                        }
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
                    const SizedBox(height: 12),
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
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
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
                    const SizedBox(height: 16),
                  ],
                  // 置顶开关
                  SwitchListTile(
                    title: const Text('是否置顶'),
                    subtitle: const Text('置顶的资产会显示在首页置顶列表'),
                    value: isPinned == 1,
                    onChanged: (value) {
                      setState(() {
                        isPinned = value ? 1 : 0;
                      });
                    },
                  ),
                  // 排除选项
                  SwitchListTile(
                    title: const Text('不计入总资产'),
                    subtitle: const Text('该资产将不参与总资产计算'),
                    value: excludeFromTotal == 1,
                    onChanged: (value) {
                      setState(() {
                        excludeFromTotal = value ? 1 : 0;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('不计入日均消费'),
                    subtitle: const Text('该资产将不参与日均消费计算'),
                    value: excludeFromDaily == 1,
                    onChanged: (value) {
                      setState(() {
                        excludeFromDaily = value ? 1 : 0;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saveAsset,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) {
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

    try {
      int? calculatedExpireDate = expireDate;
      if (category == 'subscription' && expectedDays != null) {
        calculatedExpireDate =
            purchaseDate + Duration(days: expectedDays).inMilliseconds;
      }

      final newAsset = Asset.create(
        id: widget.asset?.id,
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
      );

      await LocalDbService().saveAsset(newAsset);

      if (mounted) {
        Navigator.pop(context, newAsset);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e'), backgroundColor: Colors.red),
        );
      }
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

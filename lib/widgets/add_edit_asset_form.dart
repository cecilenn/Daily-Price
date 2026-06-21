import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../models/asset_category.dart';
import 'consumables_section.dart';
import 'date_text_field.dart';
import 'renewals_section.dart';

class AddEditAssetForm extends StatelessWidget {
  final Asset? existingAsset;
  final Widget avatarWidget;
  final VoidCallback onAvatarTap;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController expectedDaysController;
  final int status;
  final ValueChanged<int> onStatusChanged;
  final double? soldPrice;
  final ValueChanged<String> onSoldPriceChanged;
  final ValueChanged<DateTime?> onPurchaseDateChanged;
  final ValueChanged<DateTime?> onSoldDateChanged;
  final String category;
  final List<String> customCategories;
  final ValueChanged<String> onCategoryChanged;
  final String ownershipType;
  final ValueChanged<String> onOwnershipTypeChanged;
  final List<RenewalRecord> renewals;
  final VoidCallback onAddRenewal;
  final ValueChanged<String> onDeleteRenewal;
  final List<String> customTabs;
  final List<String> selectedTags;
  final void Function(String tagValue, bool selected) onTagChanged;
  final bool showConsumables;
  final List<ConsumableRecord> consumables;
  final List<ReplacementRecord> replacements;
  final ValueChanged<bool> onConsumablesEnabledChanged;
  final ValueChanged<int> onEditConsumable;
  final ValueChanged<int> onDeleteConsumable;
  final VoidCallback onAddConsumable;
  final ValueChanged<ConsumableRecord> onAddReplacement;
  final void Function(ConsumableRecord consumable, ReplacementRecord record)
  onEditReplacement;
  final ValueChanged<String> onDeleteReplacement;
  final int isPinned;
  final ValueChanged<bool> onPinnedChanged;
  final int excludeFromTotal;
  final ValueChanged<bool> onExcludeFromTotalChanged;
  final int excludeFromDaily;
  final ValueChanged<bool> onExcludeFromDailyChanged;

  const AddEditAssetForm({
    super.key,
    required this.existingAsset,
    required this.avatarWidget,
    required this.onAvatarTap,
    required this.nameController,
    required this.priceController,
    required this.expectedDaysController,
    required this.status,
    required this.onStatusChanged,
    required this.soldPrice,
    required this.onSoldPriceChanged,
    required this.onPurchaseDateChanged,
    required this.onSoldDateChanged,
    required this.category,
    required this.customCategories,
    required this.onCategoryChanged,
    required this.ownershipType,
    required this.onOwnershipTypeChanged,
    required this.renewals,
    required this.onAddRenewal,
    required this.onDeleteRenewal,
    required this.customTabs,
    required this.selectedTags,
    required this.onTagChanged,
    required this.showConsumables,
    required this.consumables,
    required this.replacements,
    required this.onConsumablesEnabledChanged,
    required this.onEditConsumable,
    required this.onDeleteConsumable,
    required this.onAddConsumable,
    required this.onAddReplacement,
    required this.onEditReplacement,
    required this.onDeleteReplacement,
    required this.isPinned,
    required this.onPinnedChanged,
    required this.excludeFromTotal,
    required this.onExcludeFromTotalChanged,
    required this.excludeFromDaily,
    required this.onExcludeFromDailyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: avatarWidget,
              ),
            ),
          ),
          const SizedBox(height: 24),
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
          TextFormField(
            controller: priceController,
            decoration: const InputDecoration(
              labelText: '购入价格 *',
              hintText: '例如：4499',
              prefixIcon: Icon(Icons.attach_money),
              prefixText: '¥ ',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final price = double.tryParse(value ?? '');
              if (price == null || price <= 0) {
                return '请输入有效的购入价格';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
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
          DateTextField(
            labelText: '购买日期',
            initialDate: existingAsset != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    existingAsset!.purchaseDate,
                  )
                : null,
            onDateChanged: onPurchaseDateChanged,
          ),
          const SizedBox(height: 20),
          const Text(
            '资产状态',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: status,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('🟢 服役中')),
              DropdownMenuItem(value: 1, child: Text('⚫ 已退役')),
              DropdownMenuItem(value: 2, child: Text('💰 已卖出')),
            ],
            onChanged: (value) {
              if (value != null) {
                onStatusChanged(value);
              }
            },
          ),
          const SizedBox(height: 16),
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
              onChanged: onSoldPriceChanged,
            ),
            const SizedBox(height: 16),
          ],
          if (status == 1 || status == 2) ...[
            DateTextField(
              labelText: status == 2 ? '卖出日期' : '退役日期',
              initialDate: existingAsset?.soldDate != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      existingAsset!.soldDate!,
                    )
                  : null,
              onDateChanged: onSoldDateChanged,
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            '资产分类',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: customCategories.contains(category)
                ? category
                : AssetCategory.uncategorized,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: customCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onCategoryChanged(value);
              }
            },
          ),
          const SizedBox(height: 16),
          const Text(
            '所有权类型',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: ownershipType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'buyout', child: Text('买断')),
              DropdownMenuItem(value: 'subscription', child: Text('订阅')),
            ],
            onChanged: (value) => onOwnershipTypeChanged(value ?? 'buyout'),
          ),
          const SizedBox(height: 16),
          if (ownershipType == 'subscription')
            RenewalsSection(
              renewals: renewals,
              onAddRenewal: onAddRenewal,
              onDeleteRenewal: onDeleteRenewal,
            ),
          if (customTabs.isNotEmpty) ...[
            const Text('自定义标签', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customTabs.map((tab) {
                final tagValue = 'custom_$tab';
                final isSelected = selectedTags.contains(tagValue);
                return FilterChip(
                  label: Text(tab),
                  selected: isSelected,
                  onSelected: (selected) => onTagChanged(tagValue, selected),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 20),
          ConsumablesSection(
            enabled: showConsumables,
            consumables: consumables,
            replacements: replacements,
            onEnabledChanged: onConsumablesEnabledChanged,
            onEditConsumable: onEditConsumable,
            onDeleteConsumable: onDeleteConsumable,
            onAddConsumable: onAddConsumable,
            onAddReplacement: onAddReplacement,
            onEditReplacement: onEditReplacement,
            onDeleteReplacement: onDeleteReplacement,
          ),
          SwitchListTile(
            title: const Text('是否置顶'),
            subtitle: const Text('置顶的资产会显示在首页置顶列表'),
            value: isPinned == 1,
            onChanged: onPinnedChanged,
          ),
          SwitchListTile(
            title: const Text('不计入总资产'),
            subtitle: const Text('该资产将不参与总资产计算'),
            value: excludeFromTotal == 1,
            onChanged: onExcludeFromTotalChanged,
          ),
          SwitchListTile(
            title: const Text('不计入日均消费'),
            subtitle: const Text('该资产将不参与日均消费计算'),
            value: excludeFromDaily == 1,
            onChanged: onExcludeFromDailyChanged,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

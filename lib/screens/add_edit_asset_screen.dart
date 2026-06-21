import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';
import '../models/asset_category.dart';
import '../providers/asset_provider.dart';
import '../services/asset_form_submission_service.dart';
import '../services/asset_preferences_service.dart';
import '../widgets/add_edit_asset_form.dart';
import '../widgets/asset_record_dialogs.dart';
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
  List<String> _customCategories = [AssetCategory.uncategorized];
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

    category = AssetCategory.normalize(widget.existingAsset?.category);
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
    final tabs = await AssetPreferencesService.loadCustomTabs();
    if (!mounted) return;
    setState(() {
      _customTabs = tabs;
    });
  }

  Future<void> _loadCustomCategories() async {
    final categories = await AssetPreferencesService.loadCustomCategories();
    if (!mounted) return;
    setState(() {
      _customCategories = categories;
    });
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
        child: AddEditAssetForm(
          existingAsset: widget.existingAsset,
          avatarWidget: _buildAvatarWidget(),
          onAvatarTap: _showAvatarEditor,
          nameController: nameController,
          priceController: priceController,
          expectedDaysController: expectedDaysController,
          status: status,
          onStatusChanged: (value) {
            setState(() {
              status = value;
              if (status != 2) soldPrice = null;
              if (status == 0) soldDate = null;
            });
          },
          soldPrice: soldPrice,
          onSoldPriceChanged: (value) {
            soldPrice = double.tryParse(value);
          },
          onPurchaseDateChanged: (date) {
            if (date != null) purchaseDate = date.millisecondsSinceEpoch;
          },
          onSoldDateChanged: (date) {
            soldDate = date?.millisecondsSinceEpoch;
          },
          category: category,
          customCategories: _customCategories,
          onCategoryChanged: (value) => setState(() => category = value),
          ownershipType: _ownershipType,
          onOwnershipTypeChanged: (value) {
            setState(() {
              _ownershipType = value;
              if (_ownershipType == 'buyout') {
                expireDate = null;
              }
            });
          },
          renewals: _renewals,
          onAddRenewal: _addRenewal,
          onDeleteRenewal: (id) {
            setState(() {
              _renewals.removeWhere((r) => r.id == id);
            });
          },
          customTabs: _customTabs,
          selectedTags: selectedTags,
          onTagChanged: (tagValue, selected) {
            setState(() {
              if (selected) {
                selectedTags.add(tagValue);
              } else {
                selectedTags.remove(tagValue);
              }
            });
          },
          showConsumables: _showConsumables,
          consumables: _consumables,
          replacements: _replacements,
          onConsumablesEnabledChanged: (value) {
            setState(() {
              _showConsumables = value;
              if (!value) {
                _consumables.clear();
                _replacements.clear();
              }
            });
          },
          onEditConsumable: _showEditConsumableDialog,
          onDeleteConsumable: (index) {
            setState(() {
              final removed = _consumables.removeAt(index);
              _replacements.removeWhere(
                (r) => r.consumableName == removed.name,
              );
            });
          },
          onAddConsumable: _showAddConsumableDialog,
          onAddReplacement: _showAddReplacementDialog,
          onEditReplacement: _showEditReplacementDialog,
          onDeleteReplacement: (id) {
            setState(() {
              _replacements.removeWhere((r) => r.id == id);
            });
          },
          isPinned: isPinned,
          onPinnedChanged: (value) => setState(() => isPinned = value ? 1 : 0),
          excludeFromTotal: excludeFromTotal,
          onExcludeFromTotalChanged: (value) =>
              setState(() => excludeFromTotal = value ? 1 : 0),
          excludeFromDaily: excludeFromDaily,
          onExcludeFromDailyChanged: (value) =>
              setState(() => excludeFromDaily = value ? 1 : 0),
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

  Future<void> _addRenewal() async {
    final result = await showRenewalDialog(context);
    if (result == null) return;

    final renewalDate = result.renewalDate.millisecondsSinceEpoch;
    var effectiveDate = renewalDate;
    if (_renewals.isNotEmpty) {
      final lastExpire = _renewals.last.expireDate;
      if (renewalDate < lastExpire) {
        effectiveDate = lastExpire;
      }
    }

    setState(() {
      _renewals.add(
        RenewalRecord(
          id: const Uuid().v4(),
          renewalDate: effectiveDate,
          price: result.price,
          durationDays: result.durationDays,
        ),
      );
      _renewals.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
    });
  }

  Future<void> _showAddConsumableDialog() async {
    final result = await showConsumableDialog(context);
    if (result == null) return;

    setState(() {
      _consumables.add(
        ConsumableRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: result.name,
          price: result.price,
          cycleDays: result.cycleDays,
          purchasedAt: result.purchasedAt.millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  Future<void> _showEditConsumableDialog(int index) async {
    final c = _consumables[index];
    final result = await showConsumableDialog(context, initial: c);
    if (result == null) return;

    setState(() {
      _consumables[index] = ConsumableRecord(
        id: c.id,
        name: result.name,
        price: result.price,
        cycleDays: result.cycleDays,
        purchasedAt: result.purchasedAt.millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  Future<void> _saveAsset() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newAsset = AssetFormSubmissionService.buildAsset(
        AssetFormSubmission(
          existingAsset: widget.existingAsset,
          assetName: nameController.text,
          purchasePriceText: priceController.text,
          expectedDaysText: expectedDaysController.text,
          purchaseDate: purchaseDate,
          isPinned: isPinned,
          status: status,
          soldPrice: soldPrice,
          soldDate: soldDate,
          category: category,
          ownershipType: _ownershipType,
          expireDate: expireDate,
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
        ),
      );

      await context.read<AssetProvider>().saveAsset(newAsset);

      if (mounted) {
        Navigator.pop(context, true); // 返回成功标志
      }
    } on AssetFormSubmissionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
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
    final result = await showReplacementDialog(
      context,
      title: '更换 ${consumable.name}',
      initialPrice: consumable.price,
    );
    if (result == null) return;

    setState(() {
      _replacements.add(
        ReplacementRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          consumableName: consumable.name,
          replacedAt: result.replacedAt.millisecondsSinceEpoch,
          price: result.price,
          note: null,
        ),
      );
    });
  }

  Future<void> _showEditReplacementDialog(
    ConsumableRecord consumable,
    ReplacementRecord record,
  ) async {
    final result = await showReplacementDialog(
      context,
      title: '编辑更换记录',
      initialPrice: record.price,
      initialDate: DateTime.fromMillisecondsSinceEpoch(record.replacedAt),
      confirmLabel: '保存',
    );
    if (result == null) return;

    setState(() {
      final idx = _replacements.indexWhere((r) => r.id == record.id);
      if (idx >= 0) {
        _replacements[idx] = ReplacementRecord(
          id: record.id,
          consumableName: record.consumableName,
          replacedAt: result.replacedAt.millisecondsSinceEpoch,
          price: result.price,
          note: record.note,
        );
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    expectedDaysController.dispose();
    super.dispose();
  }
}

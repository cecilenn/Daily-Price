import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset_category.dart';
import '../providers/asset_provider.dart';
import '../services/asset_preferences_service.dart';

/// 分类管理页面
///
/// 功能：
/// 1. 显示所有自定义分类列表
/// 2. 添加新分类
/// 3. 删除分类（删除时，该分类下的资产自动归为"未分类"）
/// 4. 不支持重命名（简化，删除再添加即可）
class CategorySettingsScreen extends StatefulWidget {
  const CategorySettingsScreen({super.key});

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen> {
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// 从 SharedPreferences 加载分类列表
  Future<void> _loadCategories() async {
    final categories = await AssetPreferencesService.loadCustomCategories();

    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    }
  }

  /// 保存分类列表到 SharedPreferences
  Future<void> _saveCategories() async {
    await AssetPreferencesService.saveCustomCategories(_categories);
  }

  /// 添加新分类
  Future<void> _addCategory() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加分类'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入分类名称',
            border: OutlineInputBorder(),
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final category = AssetPreferencesService.normalizeCategorySelection(
        result,
      );
      // 检查是否已存在
      if (_categories.contains(category)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('分类「$category」已存在'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _categories.add(category);
      });
      await _saveCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加分类「$category」'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// 删除分类
  Future<void> _deleteCategory(String category) async {
    if (category == AssetCategory.uncategorized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('「未分类」是内置分类，不可删除'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 获取该分类下的资产数量
    final provider = context.read<AssetProvider>();
    final assetsInCategory = provider.assets
        .where((a) => a.category == category)
        .toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除分类「$category」吗？'),
            if (assetsInCategory.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '该分类下有 ${assetsInCategory.length} 个资产，删除后将自动归为「未分类」。',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
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
        for (final asset in assetsInCategory) {
          final updatedAsset = asset.copyWith(
            category: AssetCategory.uncategorized,
          );
          await provider.saveAsset(updatedAsset);
        }

        // 从分类列表中移除
        setState(() {
          _categories.remove(category);
        });
        await _saveCategories();

        final defaultStartupCategory =
            await AssetPreferencesService.loadDefaultStartupCategory();
        if (defaultStartupCategory == category) {
          await AssetPreferencesService.saveDefaultStartupCategory(
            AssetCategory.uncategorized,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已删除分类「$category」'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加分类',
            onPressed: _addCategory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 分类列表
                  Card(
                    child: Column(
                      children: [
                        for (int i = 0; i < _categories.length; i++) ...[
                          ListTile(
                            leading: Icon(
                              _categories[i] == AssetCategory.uncategorized
                                  ? Icons.folder_outlined
                                  : Icons.folder,
                              color:
                                  _categories[i] == AssetCategory.uncategorized
                                  ? Colors.grey
                                  : Colors.blue,
                            ),
                            title: Text(_categories[i]),
                            subtitle: _getCategorySubtitle(_categories[i]),
                            trailing:
                                _categories[i] == AssetCategory.uncategorized
                                ? const Chip(
                                    label: Text(
                                      '内置',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    tooltip: '删除分类',
                                    onPressed: () =>
                                        _deleteCategory(_categories[i]),
                                  ),
                          ),
                          if (i < _categories.length - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 添加分类按钮
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addCategory,
                      icon: const Icon(Icons.add),
                      label: const Text('添加分类'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 说明文字
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '使用说明',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• 「未分类」是内置分类，不可删除\n'
                            '• 删除分类后，该分类下的资产会自动归为「未分类」\n'
                            '• 如需重命名分类，可先删除再添加新名称',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 获取分类副标题（显示该分类下的资产数量）
  Widget? _getCategorySubtitle(String category) {
    final provider = context.watch<AssetProvider>();
    final count = provider.assets.where((a) => a.category == category).length;

    if (count > 0) {
      return Text('$count 个资产');
    }
    return null;
  }
}

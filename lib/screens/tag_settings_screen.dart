import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/asset_provider.dart';

class TagSettingsScreen extends StatefulWidget {
  const TagSettingsScreen({super.key});

  @override
  State<TagSettingsScreen> createState() => _TagSettingsScreenState();
}

class _TagSettingsScreenState extends State<TagSettingsScreen> {
  List<String> _customTabs = [];
  final String _customTabsPrefKey = 'custom_tabs';
  final String _defaultCategoryPrefKey = 'default_startup_category';

  @override
  void initState() {
    super.initState();
    _loadCustomTabs();
  }

  /// 加载自定义标签设置
  Future<void> _loadCustomTabs() async {
    final prefs = await SharedPreferences.getInstance();
    final tabs = prefs.getStringList(_customTabsPrefKey) ?? [];
    setState(() {
      _customTabs = tabs;
    });
  }

  /// 保存自定义标签设置
  Future<void> _saveCustomTabs(List<String> tabs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customTabsPrefKey, tabs);
    setState(() {
      _customTabs = tabs;
    });
  }

  /// 添加自定义标签
  Future<void> _addCustomTab() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加自定义标签'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: '输入标签名称，如"工作"、"闲置"',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final input = controller.text.trim();
              if (input.isEmpty) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('名称不能为空'),
                    backgroundColor: Colors.red,
                    duration: Duration(milliseconds: 1000),
                  ),
                );
                return;
              }
              Navigator.pop(context, input);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (_customTabs.contains(result)) {
        _showError('该标签名称已存在');
        return;
      }
      final newTabs = [..._customTabs, result];
      await _saveCustomTabs(newTabs);
      _showSuccess('已添加标签"$result"');
    }
  }

  /// 删除自定义标签
  Future<void> _removeCustomTab(String tab) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除标签"$tab"吗？\n该标签将从所有资产中移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newTabs = _customTabs.where((t) => t != tab).toList();
      final customTabValue = 'custom_$tab';

      // 检查默认启动分栏是否是被删除的分栏
      final prefs = await SharedPreferences.getInstance();
      final defaultCategory =
          prefs.getString(_defaultCategoryPrefKey) ?? 'pinned';
      if (defaultCategory == customTabValue) {
        await prefs.setString(_defaultCategoryPrefKey, 'all');
      }

      await _saveCustomTabs(newTabs);

      final provider = context.read<AssetProvider>();
      int cleanCount = 0;

      for (final asset in provider.assets) {
        if (asset.tags.contains(customTabValue)) {
          final updatedTags = List<String>.from(asset.tags)
            ..remove(customTabValue);
          await provider.saveAsset(asset.copyWith(tags: updatedTags));
          cleanCount++;
        }
      }

      log(
        '========== [级联清洗] 已清除 $cleanCount 个资产身上的废弃标签：$customTabValue ==========',
      );

      if (cleanCount > 0) {
        _showSuccess('已删除标签"$tab"，并从 $cleanCount 个资产中移除该标签');
      } else {
        _showSuccess('已删除标签"$tab"');
      }
    }
  }

  /// 批量管理资产标签
  Future<void> _batchAddTagToAssets(String tagName) async {
    final provider = context.read<AssetProvider>();
    final customTagValue = 'custom_$tagName';

    final assets = provider.assets;
    final selectedIds = <String>{};

    for (final asset in assets) {
      if (asset.tags.contains(customTagValue)) {
        selectedIds.add(asset.id);
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('管理标签 - $tagName'),
          content: SizedBox(
            width: double.maxFinite,
            child: assets.isEmpty
                ? const Text('暂无资产数据')
                : StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '勾选添加标签，取消勾选移除标签',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setDialogState(() {
                                    if (selectedIds.length == assets.length) {
                                      selectedIds.clear();
                                    } else {
                                      selectedIds.clear();
                                      for (final a in assets) {
                                        selectedIds.add(a.id);
                                      }
                                    }
                                  });
                                },
                                child: Text(
                                  selectedIds.length == assets.length
                                      ? '取消全选'
                                      : '全选',
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '已选：${selectedIds.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: assets.length,
                              itemBuilder: (ctx, i) {
                                final asset = assets[i];
                                final String displayName =
                                    asset.assetName.isEmpty
                                    ? '未命名资产_${asset.id}'
                                    : asset.assetName;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: Colors.grey[200],
                                  child: CheckboxListTile(
                                    title: Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    value: selectedIds.contains(asset.id),
                                    onChanged: (bool? val) {
                                      if (val == null) return;
                                      setDialogState(() {
                                        if (val) {
                                          selectedIds.add(asset.id);
                                        } else {
                                          selectedIds.remove(asset.id);
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                int updateCount = 0;

                for (final asset in assets) {
                  final bool isSelected = selectedIds.contains(asset.id);
                  final bool hasTag = asset.tags.contains(customTagValue);

                  if (isSelected != hasTag) {
                    final updatedTags = List<String>.from(asset.tags);
                    if (isSelected && !hasTag) {
                      updatedTags.add(customTagValue);
                    } else if (!isSelected && hasTag) {
                      updatedTags.remove(customTagValue);
                    }
                    final updatedAsset = asset.copyWith(tags: updatedTags);
                    await provider.saveAsset(updatedAsset);
                    updateCount++;
                  }
                }

                if (mounted) {
                  Navigator.pop(context);
                  _showSuccess('成功同步 $updateCount 个资产的标签状态');
                  setState(() {});
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 显示错误提示
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 显示成功提示
  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('标签管理'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              _buildSectionHeader('自定义标签'),
              if (_customTabs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '暂无自定义标签，点击下方按钮添加',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                )
              else
                ..._customTabs.map(
                  (tab) => ListTile(
                    contentPadding: const EdgeInsets.only(
                      left: 16.0,
                      right: 8.0,
                    ),
                    leading: const Icon(Icons.label_outline),
                    title: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        tab,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.sell_outlined,
                            color: Colors.blue,
                          ),
                          tooltip: '批量添加标签',
                          onPressed: () => _batchAddTagToAssets(tab),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeCustomTab(tab),
                        ),
                      ],
                    ),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.add, color: Colors.green),
                title: const Text(
                  '添加自定义标签',
                  style: TextStyle(color: Colors.green),
                ),
                onTap: _addCustomTab,
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

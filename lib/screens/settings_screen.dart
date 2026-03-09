import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _importExportLocked = false; // 防抖保护
  
  // 默认启动分栏设置
  String _defaultCategory = 'pinned';
  final String _prefKey = 'default_startup_category';
  
  // 自定义分栏设置
  List<String> _customTabs = [];
  final String _customTabsPrefKey = 'custom_tabs';
  
  // 基础分栏选项（不含自定义分栏）
  final List<Map<String, String>> _baseCategoryOptions = [
    {'value': 'pinned', 'label': '置顶'},
    {'value': 'physical', 'label': '实体资产'},
    {'value': 'virtual', 'label': '虚拟资产'},
    {'value': 'subscription', 'label': '订阅服务'},
  ];
  
  // 获取完整的分栏选项（包含自定义分栏）
  List<Map<String, String>> get _categoryOptions {
    final options = <Map<String, String>>[
      {'value': 'all', 'label': '全部'}, // 添加"全部"选项
    ];
    options.addAll(_baseCategoryOptions);
    for (final tab in _customTabs) {
      options.add({'value': 'custom_$tab', 'label': tab});
    }
    return options;
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultCategory();
    _loadCustomTabs();
  }
  
  /// 加载默认启动分栏设置
  Future<void> _loadDefaultCategory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultCategory = prefs.getString(_prefKey) ?? 'pinned';
    });
  }
  
  /// 保存默认启动分栏设置
  Future<void> _saveDefaultCategory(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, value);
    setState(() {
      _defaultCategory = value;
    });
  }
  
  /// 加载自定义分栏设置
  Future<void> _loadCustomTabs() async {
    final prefs = await SharedPreferences.getInstance();
    final tabs = prefs.getStringList(_customTabsPrefKey) ?? [];
    setState(() {
      _customTabs = tabs;
    });
  }
  
  /// 保存自定义分栏设置
  Future<void> _saveCustomTabs(List<String> tabs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customTabsPrefKey, tabs);
    setState(() {
      _customTabs = tabs;
    });
  }
  
  /// 添加自定义分栏
  Future<void> _addCustomTab() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加自定义分栏'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入分栏名称，如"工作"、"闲置"',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      // 检查是否已存在
      if (_customTabs.contains(result)) {
        _showError('该分栏名称已存在');
        return;
      }
      final newTabs = [..._customTabs, result];
      await _saveCustomTabs(newTabs);
      _showSuccess('已添加分栏"$result"');
    }
  }
  
  /// 批量管理资产标签（双向同步：添加/取消）
  Future<void> _batchAddTagToAssets(String tagName) async {
    // 获取当前用户所有资产
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      _showError('请先登录');
      return;
    }

    try {
      // 从 Supabase 获取所有资产
      final response = await Supabase.instance.client
          .from('assets')
          .select('id, asset_name, tags')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        _showError('暂无资产可管理标签');
        return;
      }

      final List<Map<String, dynamic>> assets = (response as List)
          .map((item) => {
                'id': item['id'],
                'asset_name': item['asset_name'],
                'tags': List<String>.from(item['tags'] ?? []),
              })
          .toList();

      // 初始化选中状态：已有该标签的资产默认选中
      final Set<String> selectedAssetIds = {};
      for (final asset in assets) {
        final tags = asset['tags'] as List<String>;
        if (tags.contains(tagName)) {
          selectedAssetIds.add(asset['id'] as String);
        }
      }

      // 保存初始状态用于对比
      final Set<String> initialSelectedIds = Set.from(selectedAssetIds);

      // 显示选择对话框
      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('管理标签「$tagName」'),
            content: SizedBox(
              width: 400,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '勾选添加标签，取消勾选移除标签：',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: assets.length,
                      itemBuilder: (context, index) {
                        final asset = assets[index];
                        final assetId = asset['id'] as String;
                        final assetName = asset['asset_name'] as String;
                        final tags = asset['tags'] as List<String>;
                        final isSelected = selectedAssetIds.contains(assetId);

                        return CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          value: isSelected,
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedAssetIds.add(assetId);
                              } else {
                                selectedAssetIds.remove(assetId);
                              }
                            });
                          },
                          title: Text(assetName),
                          subtitle: tags.isNotEmpty
                              ? Text(
                                  '标签: ${tags.join(', ')}',
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  // 对比初始状态和最终状态，找出变更
                  final List<Map<String, dynamic>> toAdd = []; // 需要添加标签的资产
                  final List<Map<String, dynamic>> toRemove = []; // 需要移除标签的资产

                  for (final asset in assets) {
                    final assetId = asset['id'] as String;
                    final existingTags = asset['tags'] as List<String>;
                    final wasSelected = initialSelectedIds.contains(assetId);
                    final isNowSelected = selectedAssetIds.contains(assetId);

                    if (!wasSelected && isNowSelected) {
                      // 原来没有勾，现在勾了 -> 添加标签
                      if (!existingTags.contains(tagName)) {
                        toAdd.add({
                          'id': assetId,
                          'newTags': [...existingTags, tagName],
                        });
                      }
                    } else if (wasSelected && !isNowSelected) {
                      // 原来勾了，现在取消了 -> 移除标签
                      if (existingTags.contains(tagName)) {
                        toRemove.add({
                          'id': assetId,
                          'newTags': existingTags.where((t) => t != tagName).toList(),
                        });
                      }
                    }
                  }

                  // 批量更新数据库
                  int addedCount = 0;
                  int removedCount = 0;

                  for (final item in toAdd) {
                    await Supabase.instance.client
                        .from('assets')
                        .update({'tags': item['newTags']})
                        .eq('id', item['id']);
                    addedCount++;
                  }

                  for (final item in toRemove) {
                    await Supabase.instance.client
                        .from('assets')
                        .update({'tags': item['newTags']})
                        .eq('id', item['id']);
                    removedCount++;
                  }

                  if (mounted) {
                    final messages = <String>[];
                    if (addedCount > 0) messages.add('添加 $addedCount 个');
                    if (removedCount > 0) messages.add('移除 $removedCount 个');
                    
                    if (messages.isEmpty) {
                      _showSuccess('无变更');
                    } else {
                      _showSuccess('已${messages.join('，')}资产的标签「$tagName」');
                    }
                  }
                },
                child: const Text('确认'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _showError('获取资产列表失败: $e');
    }
  }

  /// 删除自定义分栏
  Future<void> _removeCustomTab(String tab) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分栏"$tab"吗？\n已标记该分栏的资产不会被删除。'),
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
      
      // 安全检查：如果被删除的分栏正是当前的默认分栏，重置为 'all'
      final customTabValue = 'custom_$tab';
      if (_defaultCategory == customTabValue) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, 'all');
        setState(() {
          _defaultCategory = 'all';
        });
      }
      
      await _saveCustomTabs(newTabs);
      _showSuccess('已删除分栏"$tab"');
    }
  }

  /// 格式化日期为 yyyy-MM-dd 格式
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 解析日期字符串
  DateTime? _parseDateString(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    
    final trimmed = dateStr.trim();
    
    // 尝试多种日期格式
    final formats = [
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'yyyy.MM.dd',
      'yyyy年M月d日',
      'yyyy年MM月dd日',
    ];
    
    for (final format in formats) {
      try {
        return DateFormat(format).parse(trimmed);
      } catch (_) {
        continue;
      }
    }
    
    // 尝试标准 DateTime 解析
    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  /// 显示错误提示
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 显示成功提示
  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// 导出 CSV 文件逻辑
  Future<void> _exportToCSV() async {
    // 防抖保护
    if (_importExportLocked) return;
    
    setState(() {
      _isExporting = true;
      _importExportLocked = true;
    });

    try {
      // 获取当前登录用户
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _showError('请先登录');
        return;
      }

      // 1. 从 Supabase 拉取当前用户的资产数据
      final response = await Supabase.instance.client
          .from('assets')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      // 2. 将 raw data 转化为 Asset 对象列表
      final List<Asset> assets = (response as List)
          .map((item) => Asset.fromJson(item))
          .toList();

      if (assets.isEmpty) {
        _showError('没有可导出的资产数据');
        return;
      }

      // 3. 构建 CSV 表头和数据行
      // 表头顺序：['ID', '资产名称', '购入价格', '预计使用天数', '购买日期', '是否置顶', '是否已出售', '卖出价格', '出售日期', '资产类型', '过期日期', '创建时间']
      final List<List<dynamic>> csvData = [
        ['ID', '资产名称', '购入价格', '预计使用天数', '购买日期', '是否置顶', '是否已出售', '卖出价格', '出售日期', '资产类型', '过期日期', '创建时间'],
        ...assets.map((asset) => [
          asset.id ?? '', // ID 作为第一列，用于 upsert 去重
          asset.assetName,
          asset.purchasePrice.toStringAsFixed(2),
          asset.expectedLifespanDays.toString(),
          _formatDate(asset.purchaseDate),
          asset.isPinned ? '是' : '否',
          asset.isSold ? '是' : '否',
          asset.soldPrice != null ? asset.soldPrice!.toStringAsFixed(2) : '',
          asset.soldDate != null ? _formatDate(asset.soldDate!) : '',
          asset.category, // 资产类型
          asset.expireDate != null ? _formatDate(asset.expireDate!) : '',
          _formatDate(asset.createdAt),
        ]),
      ];

      // 4. 转换为带 BOM 头（防止 Excel 中文乱码）的 CSV 格式
      final csvString = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csvString);
      // 添加 UTF-8 BOM
      final bytesWithBom = [0xEF, 0xBB, 0xBF, ...bytes];

      // 5. 根据平台选择不同的下载方式
      if (kIsWeb) {
        // Web 端下载 - 修复：必须使用 Uint8List，否则会被强制转化为 ASCII 数字字符串
        final blob = html.Blob([Uint8List.fromList(bytesWithBom)], 'text/csv;charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'assets_export_${DateTime.now().toIso8601String().split('T')[0]}.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // 桌面端/移动端下载
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: '保存 CSV 文件',
          fileName: 'assets_export_${DateTime.now().toIso8601String().split('T')[0]}.csv',
          bytes: Uint8List.fromList(bytesWithBom),
        );
        
        if (outputPath == null) {
          // 用户取消了保存
          return;
        }
      }

      _showSuccess('导出成功！共导出 ${assets.length} 条资产记录');
    } catch (e) {
      _showError('导出失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _importExportLocked = false;
        });
      }
    }
  }

  /// 导入 CSV 文件逻辑
  Future<void> _importFromCSV() async {
    // 防抖保护
    if (_importExportLocked) return;
    
    setState(() {
      _isImporting = true;
      _importExportLocked = true;
    });

    try {
      // 获取当前登录用户
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _showError('请先登录');
        return;
      }

      // 1. 选择 CSV 文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Web 端和桌面端都需要
      );

      if (result == null || result.files.isEmpty) {
        // 用户取消了选择
        return;
      }

      final file = result.files.first;
      
      // 2. 读取文件内容
      if (file.bytes == null) {
        _showError('无法读取文件内容');
        return;
      }
      
      String csvContent = utf8.decode(file.bytes!);

      // 3. 解析 CSV 数据
      // 尝试检测并移除 BOM 头
      String normalizedContent = csvContent;
      if (csvContent.startsWith('\ufeff')) {
        normalizedContent = csvContent.substring(1);
      }

      final List<List<dynamic>> csvRows = const CsvToListConverter().convert(normalizedContent);
      
      if (csvRows.length < 2) {
        _showError('CSV 文件为空或格式不正确');
        return;
      }

      // 4. 忽略第一行表头，解析数据行
      final List<Map<String, dynamic>> assetsToUpsert = [];
      int skippedRows = 0;

      for (int i = 1; i < csvRows.length; i++) {
        final row = csvRows[i];
        
        // 确保行有足够的列数（至少需要 9 列：ID + 8 个基本字段）
        if (row.length < 9) {
          skippedRows++;
          continue;
        }

        try {
          // 解析每一行数据
          // 新表头顺序：['ID', '资产名称', '购入价格', '预计使用天数', '购买日期', '是否置顶', '是否已出售', '卖出价格', '出售日期', '资产类型', '过期日期', '创建时间']
          // 兼容旧格式（无 ID 列）：['资产名称', '购入价格', ...]
          
          // 检测是否有 ID 列（通过检查第一行表头判断）
          final firstRowHeader = csvRows[0][0]?.toString() ?? '';
          final hasIdColumn = firstRowHeader == 'ID';
          
          int colOffset = 0;
          String? assetId;
          
          if (hasIdColumn) {
            // 新格式：第一列是 ID
            assetId = row[0]?.toString().trim() ?? '';
            colOffset = 0;
          }
          
          final assetName = row[colOffset + 0]?.toString().trim() ?? '';
          if (assetName.isEmpty) {
            skippedRows++;
            continue;
          }

          final purchasePrice = double.tryParse(row[colOffset + 1]?.toString() ?? '0') ?? 0.0;
          final expectedLifespanDays = int.tryParse(row[colOffset + 2]?.toString() ?? '0') ?? 0;
          
          // 解析购买日期
          DateTime? purchaseDate = _parseDateString(row[colOffset + 3]?.toString() ?? '');
          if (purchaseDate == null) {
            purchaseDate = DateTime.now();
          }

          // 解析布尔值
          final isPinned = row[colOffset + 4]?.toString() == '是' || row[colOffset + 4]?.toString().toLowerCase() == 'true';
          final isSold = row[colOffset + 5]?.toString() == '是' || row[colOffset + 5]?.toString().toLowerCase() == 'true';

          // 解析卖出价格
          double? soldPrice;
          if (row.length > colOffset + 6 && row[colOffset + 6] != null && row[colOffset + 6].toString().isNotEmpty) {
            soldPrice = double.tryParse(row[colOffset + 6].toString());
          }

          // 解析出售日期
          DateTime? soldDate;
          if (row.length > colOffset + 7 && row[colOffset + 7] != null && row[colOffset + 7].toString().isNotEmpty) {
            soldDate = _parseDateString(row[colOffset + 7].toString());
          }
          
          // 解析资产类型（新字段）
          String category = 'physical';
          if (row.length > colOffset + 9 && row[colOffset + 9] != null && row[colOffset + 9].toString().isNotEmpty) {
            final cat = row[colOffset + 9].toString().trim();
            if (['physical', 'virtual', 'subscription'].contains(cat)) {
              category = cat;
            }
          }
          
          // 解析过期日期（新字段）
          DateTime? expireDate;
          if (row.length > colOffset + 10 && row[colOffset + 10] != null && row[colOffset + 10].toString().isNotEmpty) {
            expireDate = _parseDateString(row[colOffset + 10].toString());
          }

          // 构建要插入/更新的数据 - 强制加上当前登录用户的 user_id
          final assetData = {
            'user_id': currentUser.id, // 核心：强制加上当前登录用户的 user_id
            'asset_name': assetName,
            'purchase_price': purchasePrice,
            'expected_lifespan_days': expectedLifespanDays,
            'purchase_date': purchaseDate.toIso8601String(),
            'is_pinned': isPinned,
            'is_sold': isSold,
            'category': category,
            if (soldPrice != null) 'sold_price': soldPrice,
            if (soldDate != null) 'sold_date': soldDate.toIso8601String(),
            if (expireDate != null) 'expire_date': expireDate.toIso8601String(),
          };
          
          // 如果有 ID，添加到数据中用于 upsert
          if (hasIdColumn && assetId != null && assetId!.isNotEmpty) {
            assetData['id'] = assetId!;
          }
          
          assetsToUpsert.add(assetData);
        } catch (e) {
          skippedRows++;
          continue;
        }
      }

      if (assetsToUpsert.isEmpty) {
        _showError('没有有效的数据可导入${skippedRows > 0 ? '，跳过了 $skippedRows 行无效数据' : ''}');
        return;
      }

      // 5. 批量上传到 Supabase - 使用 upsert 避免重复
      await Supabase.instance.client
          .from('assets')
          .upsert(assetsToUpsert, onConflict: 'id');

      _showSuccess('导入成功！共导入 ${assetsToUpsert.length} 条资产记录${skippedRows > 0 ? '，跳过了 $skippedRows 行无效数据' : ''}');
    } catch (e) {
      _showError('导入失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importExportLocked = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              // 外观分区
              _buildSectionHeader('外观'),
              
              // 主题切换
              Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  return ListTile(
                    leading: Icon(
                      appProvider.theme == AppTheme.light 
                          ? Icons.light_mode 
                          : appProvider.theme == AppTheme.dark 
                              ? Icons.dark_mode 
                              : Icons.eco,
                    ),
                    title: const Text('主题风格'),
                    subtitle: Text(_getThemeName(appProvider.theme)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeDialog(appProvider),
                  );
                },
              ),
              const Divider(height: 1),
              
              // 默认启动分栏
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('默认启动分栏'),
                subtitle: Text(_getCategoryLabel(_defaultCategory)),
                trailing: DropdownButton<String>(
                  value: _defaultCategory,
                  underline: const SizedBox(),
                  items: _categoryOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _saveDefaultCategory(newValue);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              
              const SizedBox(height: 16),
              
              // 自定义分栏管理分区
              _buildSectionHeader('自定义分栏'),
              
              // 自定义分栏列表
              if (_customTabs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '暂无自定义分栏，点击下方按钮添加',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                )
              else
                ..._customTabs.map((tab) => ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: Text(tab),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 添加标签按钮
                      IconButton(
                        icon: const Icon(Icons.sell_outlined, color: Colors.blue),
                        tooltip: '批量添加标签',
                        onPressed: () => _batchAddTagToAssets(tab),
                      ),
                      // 删除按钮
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeCustomTab(tab),
                      ),
                    ],
                  ),
                )),
              
              // 添加自定义分栏按钮
              ListTile(
                leading: const Icon(Icons.add, color: Colors.green),
                title: const Text('添加自定义分栏', style: TextStyle(color: Colors.green)),
                onTap: _addCustomTab,
              ),
              const Divider(height: 1),
              
              const SizedBox(height: 16),
              
              // 数据管理分区
              _buildSectionHeader('数据管理'),
              
              // 导出数据
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('导出数据存档'),
                subtitle: const Text('将所有资产数据导出为 CSV 文件'),
                trailing: _isExporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _isExporting ? null : _exportToCSV,
              ),
              const Divider(height: 1),
              
              // 导入数据
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('导入本地存档'),
                subtitle: const Text('从 CSV 文件导入资产数据'),
                trailing: _isImporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _isImporting ? null : _importFromCSV,
              ),
              const Divider(height: 1),
              
              const SizedBox(height: 16),
              
              // 账户分区
              _buildSectionHeader('账户'),
              
              // 退出登录
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('退出登录', style: TextStyle(color: Colors.red)),
                subtitle: const Text('退出当前账户'),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认退出'),
                      content: const Text('确定要退出登录吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('退出', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
              
              const SizedBox(height: 32),
              
              // 关于分区
              _buildSectionHeader('关于'),
              
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本'),
                subtitle: const Text('1.0.0'),
              ),
              
              const SizedBox(height: 48),
              
              // 底部提示
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '提示：导入数据时，所有资产将关联到当前登录账户。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取主题名称
  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return '极简留白';
      case AppTheme.dark:
        return '暗黑模式';
      case AppTheme.green:
        return '复古护眼';
    }
  }
  
  /// 获取分栏显示名称
  String _getCategoryLabel(String value) {
    for (final option in _categoryOptions) {
      if (option['value'] == value) {
        return option['label']!;
      }
    }
    return '置顶';
  }

  /// 显示主题选择对话框
  void _showThemeDialog(AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              appProvider,
              AppTheme.light,
              '极简留白',
              Icons.light_mode,
              '清爽明亮的浅色主题',
            ),
            const Divider(height: 1),
            _buildThemeOption(
              appProvider,
              AppTheme.dark,
              '暗黑模式',
              Icons.dark_mode,
              '护眼舒适的深色主题',
            ),
            const Divider(height: 1),
            _buildThemeOption(
              appProvider,
              AppTheme.green,
              '复古护眼',
              Icons.eco,
              '温和的绿色护眼主题',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建主题选项
  Widget _buildThemeOption(
    AppProvider appProvider,
    AppTheme theme,
    String name,
    IconData icon,
    String description,
  ) {
    final isSelected = appProvider.theme == theme;
    
    return ListTile(
      leading: Icon(icon),
      title: Text(name),
      subtitle: Text(
        description,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        appProvider.setTheme(theme);
        Navigator.pop(context);
      },
    );
  }

  /// 构建分区标题
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
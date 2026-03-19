import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../models/asset.dart';
import '../providers/app_provider.dart';
import '../services/local_db_service.dart';

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
      {'value': 'all', 'label': '全部'},
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
          maxLength: 20,
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
        _showError('该分栏名称已存在');
        return;
      }
      final newTabs = [..._customTabs, result];
      await _saveCustomTabs(newTabs);
      _showSuccess('已添加分栏"$result"');
    }
  }

  /// 批量管理资产标签
  Future<void> _batchAddTagToAssets(String tagName) async {
    final db = LocalDbService();
    final customTagValue = 'custom_$tagName';

    final assets = await db.getAllAssets();
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
                    await db.saveAsset(updatedAsset);
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

  /// 删除自定义分栏
  Future<void> _removeCustomTab(String tab) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分栏"$tab"吗？\n该分栏标签将从所有资产中移除。'),
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

      if (_defaultCategory == customTabValue) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, 'all');
        setState(() {
          _defaultCategory = 'all';
        });
      }

      await _saveCustomTabs(newTabs);

      final db = LocalDbService();
      final allAssets = await db.getAllAssets();
      int cleanCount = 0;

      for (final asset in allAssets) {
        if (asset.tags.contains(customTabValue)) {
          final updatedTags = List<String>.from(asset.tags);
          updatedTags.remove(customTabValue);
          final updatedAsset = asset.copyWith(tags: updatedTags);
          await db.saveAsset(updatedAsset);
          cleanCount++;
        }
      }

      print(
        '========== [级联清洗] 已清除 $cleanCount 个资产身上的废弃标签：$customTabValue ==========',
      );

      if (cleanCount > 0) {
        _showSuccess('已删除分栏"$tab"，并从 $cleanCount 个资产中移除该标签');
      } else {
        _showSuccess('已删除分栏"$tab"');
      }
    }
  }

  /// 格式化时间戳为 yyyy-MM-dd 格式
  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd').format(date);
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

  /// 导出 CSV 文件逻辑
  Future<void> _exportToCSV() async {
    if (_importExportLocked) {
      debugPrint('[导出] 操作被锁定，跳过');
      return;
    }

    setState(() {
      _isExporting = true;
      _importExportLocked = true;
    });

    try {
      debugPrint('[导出] 开始导出流程...');

      final assets = await LocalDbService().getAllAssets();
      debugPrint('[导出] 获取到 ${assets.length} 条资产');

      if (assets.isEmpty) {
        _showError('暂无数据可导出');
        return;
      }

      // 构建 CSV 数据 - 使用 V2.0 新字段
      final csvData = <List<dynamic>>[
        [
          'id',
          'asset_name',
          'purchase_price',
          'expected_lifespan_days',
          'purchase_date',
          'is_pinned',
          'status',
          'sold_price',
          'sold_date',
          'category',
          'expire_date',
          'tags',
          'created_at',
        ],
      ];

      for (final asset in assets) {
        csvData.add([
          asset.id,
          asset.assetName,
          asset.purchasePrice ?? '',
          asset.expectedLifespanDays ?? '',
          _formatTimestamp(asset.purchaseDate),
          asset.isPinned == 1 ? 'true' : 'false',
          asset.status, // 0 服役中，1 已退役，2 已卖出
          asset.soldPrice ?? '',
          _formatTimestamp(asset.soldDate),
          asset.category,
          _formatTimestamp(asset.expireDate),
          asset.tags.join(';'),
          _formatTimestamp(asset.createdAt),
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      debugPrint('[导出] CSV 字符串长度：${csvString.length}');

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultFileName = 'daily_price_backup_$timestamp.csv';
      debugPrint('[导出] 默认文件名：$defaultFileName');

      if (kIsWeb) {
        debugPrint('[导出] Web 平台，使用 Blob 下载');
        final bytes = utf8.encode(csvString);
        final blob = html.Blob([bytes], 'text/csv', 'native');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', defaultFileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSuccess('已导出 ${assets.length} 条资产数据');
      } else if (Platform.isAndroid) {
        debugPrint('[导出] Android 平台，尝试 saveFile');

        try {
          final tempDir = await getTemporaryDirectory();
          final tempFilePath = '${tempDir.path}/$defaultFileName';
          final tempFile = File(tempFilePath);
          await tempFile.writeAsString(csvString);
          debugPrint('[导出] 临时文件已创建：$tempFilePath');

          final savePath = await FilePicker.platform.saveFile(
            dialogTitle: '保存 CSV 文件',
            fileName: defaultFileName,
            type: FileType.custom,
            allowedExtensions: ['csv'],
            bytes: Uint8List.fromList(utf8.encode(csvString)),
          );

          if (savePath == null) {
            debugPrint('[导出] 用户取消保存');
            return;
          }

          if (savePath.isNotEmpty) {
            debugPrint('[导出] saveFile 返回路径：$savePath');
            _showSuccess('已保存到：$savePath');
          } else {
            debugPrint('[导出] saveFile 返回空字符串，尝试备选方案');
            await _exportToAndroidDownload(csvString, defaultFileName);
          }
        } on PlatformException catch (e) {
          debugPrint('[导出] PlatformException: ${e.code} - ${e.message}');
          _showError('saveFile 失败：${e.code} - ${e.message}');
          await _exportToAndroidDownload(csvString, defaultFileName);
        } catch (e) {
          debugPrint('[导出] saveFile 异常：$e');
          _showError('保存失败：${e.toString()}');
          await _exportToAndroidDownload(csvString, defaultFileName);
        }
      } else {
        debugPrint('[导出] 桌面端平台，使用 saveFile');

        try {
          final savePath = await FilePicker.platform.saveFile(
            dialogTitle: '保存 CSV 文件',
            fileName: defaultFileName,
            type: FileType.custom,
            allowedExtensions: ['csv'],
            bytes: Uint8List.fromList(utf8.encode(csvString)),
          );

          if (savePath == null) {
            debugPrint('[导出] 用户取消保存');
            return;
          }

          if (savePath.isNotEmpty) {
            debugPrint('[导出] 文件已保存到：$savePath');
            _showSuccess('已保存到：$savePath');
          }
        } on PlatformException catch (e) {
          debugPrint('[导出] PlatformException: ${e.code} - ${e.message}');
          _showError('保存失败：${e.code} - ${e.message}');
        } catch (e) {
          debugPrint('[导出] 保存异常：$e');
          _showError('保存失败：${e.toString()}');
        }
      }

      debugPrint('[导出] 导出流程完成');
    } catch (e, stackTrace) {
      debugPrint('[导出] 发生错误：$e');
      debugPrint('[导出] 堆栈：$stackTrace');
      _showError('导出失败：${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _importExportLocked = false;
        });
      }
    }
  }

  /// Android 备选导出方案
  Future<void> _exportToAndroidDownload(
    String csvString,
    String fileName,
  ) async {
    try {
      debugPrint('[导出] 尝试写入 Download 目录');

      final downloadDir = Directory('/storage/emulated/0/Download');

      if (await downloadDir.exists()) {
        final filePath = '${downloadDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsString(csvString);
        debugPrint('[导出] 已写入 Download 目录：$filePath');
        _showSuccess('已保存到下载目录：$fileName');
      } else {
        debugPrint('[导出] Download 目录不存在');
        final tempDir = await getTemporaryDirectory();
        final tempFilePath = '${tempDir.path}/$fileName';
        final tempFile = File(tempFilePath);
        await tempFile.writeAsString(csvString);
        debugPrint('[导出] 已写入临时目录：$tempFilePath');
        _showSuccess('已保存到临时目录：$fileName\n路径：$tempFilePath');
      }
    } catch (e) {
      debugPrint('[导出] 备选方案失败：$e');
      _showError('保存失败，请检查存储权限：${e.toString()}');
    }
  }

  /// 导入 CSV 文件逻辑
  Future<void> _importFromCSV() async {
    if (_importExportLocked) {
      debugPrint('[导入] 操作被锁定，跳过');
      return;
    }

    setState(() {
      _isImporting = true;
      _importExportLocked = true;
    });

    try {
      debugPrint('[导入] 开始导入流程...');

      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择 CSV 文件',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[导入] 用户取消选择');
        return;
      }

      final file = result.files.first;
      debugPrint('[导入] 选中文件：${file.name}');
      String csvString;

      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) {
          _showError('无法读取文件内容：bytes 为空');
          return;
        }
        csvString = utf8.decode(bytes);
      } else {
        if (file.path == null) {
          _showError('无法获取文件路径：path 为空');
          return;
        }
        csvString = await File(file.path!).readAsString();
      }

      debugPrint('[导入] CSV 字符串长度：${csvString.length}');

      final csvRows = const CsvToListConverter().convert(csvString);
      debugPrint('[导入] 解析到 ${csvRows.length} 行（含表头）');

      if (csvRows.length < 2) {
        _showError('CSV 文件为空或格式不正确（仅有 ${csvRows.length} 行）');
        return;
      }

      final header = csvRows[0]
          .map((e) => e.toString().trim().toLowerCase())
          .toList();
      debugPrint('[导入] 表头：$header');

      final Map<String, int> fieldIndex = {};
      for (int i = 0; i < header.length; i++) {
        fieldIndex[header[i]] = i;
      }

      final hasAssetName =
          fieldIndex.containsKey('asset_name') ||
          fieldIndex.containsKey('name') ||
          fieldIndex.containsKey('title');
      if (!hasAssetName) {
        _showError('CSV 缺少必要字段：asset_name 或 name 或 title\n当前表头：$header');
        return;
      }

      final assetsToImport = <Asset>[];
      int skippedRows = 0;

      for (int i = 1; i < csvRows.length; i++) {
        final row = csvRows[i];
        if (row.isEmpty) {
          skippedRows++;
          continue;
        }

        try {
          String? getRowValue(List<String> possibleFieldNames) {
            for (final fieldName in possibleFieldNames) {
              final idx = fieldIndex[fieldName.toLowerCase()];
              if (idx != null && idx < row.length) {
                final val = row[idx];
                return (val == null || val.toString().trim().isEmpty)
                    ? null
                    : val.toString().trim();
              }
            }
            return null;
          }

          final assetName = getRowValue(['asset_name', 'name', 'title']);
          if (assetName == null || assetName.isEmpty) {
            debugPrint('[导入] 第 $i 行缺少资产名称，跳过');
            skippedRows++;
            continue;
          }

          final id = getRowValue(['id', 'uuid']) ?? '';

          final purchasePriceStr = getRowValue(['purchase_price', 'price']);
          final purchasePrice = purchasePriceStr != null
              ? double.tryParse(purchasePriceStr)
              : null;

          final lifespanStr = getRowValue([
            'expected_lifespan_days',
            'lifespan_days',
            'lifespan',
          ]);
          final expectedLifespanDays = lifespanStr != null
              ? int.tryParse(lifespanStr)
              : null;

          final purchaseDateStr = getRowValue([
            'purchase_date',
            'buy_date',
            'date',
          ]);
          final purchaseDate =
              _parseDateString(purchaseDateStr)?.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch;

          final isPinnedStr = getRowValue(['is_pinned', 'pinned']);
          final isPinned = isPinnedStr?.toLowerCase() == 'true' ? 1 : 0;

          // 支持旧的 is_sold 字段映射到 status
          final isSoldStr = getRowValue(['is_sold', 'sold']);
          final isSold = isSoldStr?.toLowerCase() == 'true';

          // 支持 status 字段或从 is_sold 转换
          final statusStr = getRowValue(['status']);
          int status = 0; // 默认服役中
          if (statusStr != null) {
            status = int.tryParse(statusStr) ?? 0;
          } else if (isSold) {
            status = 2; // 已卖出
          }

          final soldPriceStr = getRowValue(['sold_price', 'sell_price']);
          final soldPrice = soldPriceStr != null
              ? double.tryParse(soldPriceStr)
              : null;

          final soldDateStr = getRowValue(['sold_date', 'sell_date']);
          final soldDate = _parseDateString(
            soldDateStr,
          )?.millisecondsSinceEpoch;

          final category = getRowValue(['category', 'type']) ?? 'physical';

          final expireDateStr = getRowValue(['expire_date', 'expiry_date']);
          final expireDate = _parseDateString(
            expireDateStr,
          )?.millisecondsSinceEpoch;

          final tagsStr = getRowValue(['tags', 'tag']);
          final tags = tagsStr != null && tagsStr.isNotEmpty
              ? tagsStr
                    .split(';')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList()
              : <String>[];

          final createdAtStr = getRowValue([
            'created_at',
            'created_date',
            'created',
          ]);
          final createdAt =
              _parseDateString(createdAtStr)?.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch;

          final asset = Asset(
            id: id,
            assetName: assetName,
            purchasePrice: purchasePrice,
            expectedLifespanDays: expectedLifespanDays,
            purchaseDate: purchaseDate,
            isPinned: isPinned,
            status: status,
            soldPrice: soldPrice,
            soldDate: soldDate,
            category: category,
            expireDate: expireDate,
            tags: tags,
            createdAt: createdAt,
          );

          assetsToImport.add(asset);
        } catch (e) {
          debugPrint('[导入] 第 $i 行解析失败：$e');
          skippedRows++;
          continue;
        }
      }

      debugPrint('[导入] 解析完成：${assetsToImport.length} 条有效，$skippedRows 条跳过');

      if (assetsToImport.isEmpty) {
        _showError('没有有效的资产数据可导入\n共跳过 $skippedRows 行');
        return;
      }

      final (insertedCount, updatedCount) = await LocalDbService()
          .importAssetsWithUpsert(assetsToImport);

      debugPrint('[导入] 导入完成：新增 $insertedCount 条，更新 $updatedCount 条');

      if (mounted) {
        setState(() {});
      }

      _showSuccess('导入完成：新增 $insertedCount 条，更新 $updatedCount 条');
    } catch (e, stackTrace) {
      debugPrint('[导入] 发生错误：$e');
      debugPrint('[导入] 堆栈：$stackTrace');
      _showError('导入失败：${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importExportLocked = false;
        });
      }
    }
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
      'yyyy 年 M 月 d 日',
      'yyyy 年 MM 月 dd 日',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(trimmed);
      } catch (_) {
        continue;
      }
    }

    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              _buildSectionHeader('外观'),

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

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '默认启动分栏',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      width: 160,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _defaultCategory,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          items: _categoryOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option['value'],
                              child: Text(
                                option['label']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _saveDefaultCategory(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              const SizedBox(height: 16),

              _buildSectionHeader('自定义分栏'),

              if (_customTabs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '暂无自定义分栏，点击下方按钮添加',
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
                  '添加自定义分栏',
                  style: TextStyle(color: Colors.green),
                ),
                onTap: _addCustomTab,
              ),
              const Divider(height: 1),

              const SizedBox(height: 16),

              _buildSectionHeader('数据管理'),

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

              _buildSectionHeader('账户'),

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
                          child: const Text(
                            '退出',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),

              const SizedBox(height: 32),

              _buildSectionHeader('关于'),

              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本'),
                subtitle: const Text('1.0.0'),
              ),

              const SizedBox(height: 48),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '提示：导入数据时，所有资产将关联到当前登录账户。',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../services/local_db_service.dart';
import '../services/cloud_sync_service.dart';
import 'login_screen.dart';

class DataSettingsScreen extends StatefulWidget {
  const DataSettingsScreen({super.key});

  @override
  State<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends State<DataSettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _importExportLocked = false; // 防抖保护
  String? _lastSyncTimeText; // 云端最后同步时间

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
  }

  /// 加载云端最后同步时间
  Future<void> _loadLastSyncTime() async {
    if (!CloudSyncService.instance.isLoggedIn) return;

    try {
      final lastSyncTime = await CloudSyncService.instance.getLastSyncTime();
      if (lastSyncTime != null && mounted) {
        setState(() {
          _lastSyncTimeText = DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(lastSyncTime);
        });
      }
    } catch (e) {
      debugPrint('获取云端同步时间失败：$e');
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

      final (insertedCount, updatedCount) = await context
          .read<AssetProvider>()
          .importAssets(assetsToImport);

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
      appBar: AppBar(title: const Text('数据管理'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              // 云端同步卡片
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CloudSyncService.instance.isLoggedIn
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '☁️ 云端同步',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '账号：${CloudSyncService.instance.userEmail}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (_lastSyncTimeText != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '云端存档：$_lastSyncTimeText',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 12),

                            // 同步到云端
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.cloud_upload),
                              title: const Text('同步到云端'),
                              subtitle: const Text('将本地数据覆盖到云端'),
                              onTap: () async {
                                final assets = await LocalDbService()
                                    .getAllAssets();
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('同步到云端'),
                                    content: Text(
                                      '将本地 ${assets.length} 条资产上传到云端，覆盖云端数据？',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('确认'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    final (inserted, updated, deleted) = await CloudSyncService
                                        .instance
                                        .syncUp(assets);
                                    _showSuccess('同步完成：新增 $inserted，更新 $updated，删除 $deleted');
                                  } catch (e) {
                                    _showError('上传失败：${e.toString()}');
                                  }
                                }
                              },
                            ),

                            // 同步到本地
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.cloud_download),
                              title: const Text('同步到本地'),
                              subtitle: const Text('将云端数据覆盖到本地'),
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('同步到本地'),
                                    content: const Text('将云端数据下载到本地，覆盖本地所有资产？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('确认'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    final assets = await CloudSyncService
                                        .instance
                                        .syncDown();
                                    final (
                                      insertedCount,
                                      updatedCount,
                                    ) = await context
                                        .read<AssetProvider>()
                                        .importAssets(assets);
                                    _showSuccess(
                                      '同步完成：新增 $insertedCount 条，更新 $updatedCount 条',
                                    );
                                  } catch (e) {
                                    _showError('同步失败：${e.toString()}');
                                  }
                                }
                              },
                            ),

                            // 退出登录
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () async {
                                await Supabase.instance.client.auth.signOut();
                                if (context.mounted) setState(() {});
                              },
                              child: const Text(
                                '退出登录',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Text(
                              '☁️ 云端同步',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '登录后可将数据同步到云端备份',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.login),
                              label: const Text('登录'),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                                // 登录回来后刷新页面
                                if (mounted) setState(() {});
                              },
                            ),
                          ],
                        ),
                ),
              ),

              _buildSectionHeader('数据备份'),
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

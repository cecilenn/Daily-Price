import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/asset_provider.dart';
import '../services/asset_archive_service.dart';
import '../services/asset_csv_service.dart';
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
      return;
    }

    setState(() {
      _isExporting = true;
      _importExportLocked = true;
    });

    try {
      final result = await AssetArchiveService.exportAllAssets();
      if (!mounted || result.isCanceled) return;

      if (result.successMessage != null) {
        _showSuccess(result.successMessage!);
      } else if (result.errorMessage != null) {
        _showError(result.errorMessage!);
      }
    } catch (e) {
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

  /// 导入 CSV 文件逻辑
  Future<void> _importFromCSV() async {
    if (_importExportLocked) {
      return;
    }

    setState(() {
      _isImporting = true;
      _importExportLocked = true;
    });

    try {
      final archive = await AssetArchiveService.pickCsvString();
      if (!mounted || archive.isCanceled) return;
      if (archive.errorMessage != null) {
        _showError(archive.errorMessage!);
        return;
      }

      final csvString = archive.csvString;
      if (csvString == null) {
        _showError('无法读取文件内容');
        return;
      }

      final parseResult = AssetCsvService.parse(csvString);
      final assetsToImport = parseResult.assets;
      final skippedRows = parseResult.skippedRows;

      if (assetsToImport.isEmpty) {
        _showError('没有有效的资产数据可导入\n共跳过 $skippedRows 行');
        return;
      }

      if (!mounted) return;
      final assetProvider = context.read<AssetProvider>();
      final (insertedCount, updatedCount) = await assetProvider.importAssets(
        assetsToImport,
      );
      if (!mounted) return;

      if (mounted) {
        setState(() {});
      }

      _showSuccess('导入完成：新增 $insertedCount 条，更新 $updatedCount 条');
    } catch (e) {
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
                              title: const Text('上传覆盖云端'),
                              subtitle: const Text('用本地资产完整覆盖云端资产'),
                              onTap: () async {
                                final assets = await LocalDbService()
                                    .getAllAssets();
                                if (!context.mounted) return;
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('上传覆盖云端'),
                                    content: Text(
                                      '将用本地 ${assets.length} 条资产覆盖云端资产。云端多余资产会被删除，确定继续？',
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
                                        child: const Text('确认覆盖'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    final (
                                      inserted,
                                      updated,
                                      deleted,
                                    ) = await CloudSyncService.instance.syncUp(
                                      assets,
                                    );
                                    _showSuccess(
                                      '同步完成：新增 $inserted，更新 $updated，删除 $deleted',
                                    );
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
                              title: const Text('下载覆盖本地'),
                              subtitle: const Text('用云端资产完整覆盖本地资产'),
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('下载覆盖本地'),
                                    content: const Text(
                                      '将用云端资产覆盖本地所有资产。本地未上传的数据会丢失，确定继续？',
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
                                        child: const Text('确认覆盖'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    final assets = await CloudSyncService
                                        .instance
                                        .syncDown();
                                    if (!context.mounted) return;
                                    final assetProvider = context
                                        .read<AssetProvider>();
                                    final replacedCount = await assetProvider
                                        .replaceAssets(assets);
                                    if (!mounted) return;
                                    _showSuccess(
                                      '同步完成：本地已覆盖为 $replacedCount 条云端资产',
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

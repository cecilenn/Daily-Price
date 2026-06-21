import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

import 'asset_csv_service.dart';
import 'local_db_service.dart';

class AssetArchiveExportResult {
  final int assetCount;
  final String? successMessage;
  final String? errorMessage;
  final bool isCanceled;

  const AssetArchiveExportResult._({
    required this.assetCount,
    this.successMessage,
    this.errorMessage,
    this.isCanceled = false,
  });

  const AssetArchiveExportResult.success({
    required int assetCount,
    required String message,
  }) : this._(assetCount: assetCount, successMessage: message);

  const AssetArchiveExportResult.empty()
    : this._(assetCount: 0, errorMessage: '暂无数据可导出');

  const AssetArchiveExportResult.canceled({required int assetCount})
    : this._(assetCount: assetCount, isCanceled: true);

  const AssetArchiveExportResult.failed({
    required int assetCount,
    required String message,
  }) : this._(assetCount: assetCount, errorMessage: message);
}

class AssetArchiveImportResult {
  final String? csvString;
  final bool isCanceled;
  final String? errorMessage;

  const AssetArchiveImportResult._({
    this.csvString,
    this.isCanceled = false,
    this.errorMessage,
  });

  const AssetArchiveImportResult.loaded(String csvString)
    : this._(csvString: csvString);

  const AssetArchiveImportResult.canceled() : this._(isCanceled: true);

  const AssetArchiveImportResult.failed(String message)
    : this._(errorMessage: message);
}

class AssetArchiveService {
  static Future<AssetArchiveExportResult> exportAllAssets() async {
    final assets = await LocalDbService().getAllAssets();
    if (assets.isEmpty) {
      return const AssetArchiveExportResult.empty();
    }

    final csvString = AssetCsvService.encode(assets);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final defaultFileName = 'daily_price_backup_$timestamp.csv';

    if (kIsWeb) {
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes], 'text/csv', 'native');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', defaultFileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      return AssetArchiveExportResult.success(
        assetCount: assets.length,
        message: '已导出 ${assets.length} 条资产数据',
      );
    }

    if (Platform.isAndroid) {
      return _exportOnAndroid(csvString, defaultFileName, assets.length);
    }

    return _exportOnDesktop(csvString, defaultFileName, assets.length);
  }

  static Future<AssetArchiveImportResult> pickCsvString() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择 CSV 文件',
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return const AssetArchiveImportResult.canceled();
    }

    final file = result.files.first;
    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) {
        return const AssetArchiveImportResult.failed('无法读取文件内容：bytes 为空');
      }
      return AssetArchiveImportResult.loaded(utf8.decode(bytes));
    }

    final path = file.path;
    if (path == null) {
      return const AssetArchiveImportResult.failed('无法获取文件路径：path 为空');
    }

    return AssetArchiveImportResult.loaded(await File(path).readAsString());
  }

  static Future<AssetArchiveExportResult> _exportOnAndroid(
    String csvString,
    String fileName,
    int assetCount,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/$fileName';
      await File(tempFilePath).writeAsString(csvString);

      final savePath = await _saveCsv(csvString, fileName);
      if (savePath == null) {
        return AssetArchiveExportResult.canceled(assetCount: assetCount);
      }
      if (savePath.isNotEmpty) {
        return AssetArchiveExportResult.success(
          assetCount: assetCount,
          message: '已保存到：$savePath',
        );
      }

      return _exportToAndroidDownload(csvString, fileName, assetCount);
    } on PlatformException catch (e) {
      final fallback = await _exportToAndroidDownload(
        csvString,
        fileName,
        assetCount,
      );
      if (fallback.successMessage != null) return fallback;
      return AssetArchiveExportResult.failed(
        assetCount: assetCount,
        message: 'saveFile 失败：${e.code} - ${e.message}',
      );
    } catch (e) {
      final fallback = await _exportToAndroidDownload(
        csvString,
        fileName,
        assetCount,
      );
      if (fallback.successMessage != null) return fallback;
      return AssetArchiveExportResult.failed(
        assetCount: assetCount,
        message: '保存失败：$e',
      );
    }
  }

  static Future<AssetArchiveExportResult> _exportOnDesktop(
    String csvString,
    String fileName,
    int assetCount,
  ) async {
    try {
      final savePath = await _saveCsv(csvString, fileName);
      if (savePath == null) {
        return AssetArchiveExportResult.canceled(assetCount: assetCount);
      }
      if (savePath.isEmpty) {
        return AssetArchiveExportResult.canceled(assetCount: assetCount);
      }
      return AssetArchiveExportResult.success(
        assetCount: assetCount,
        message: '已保存到：$savePath',
      );
    } on PlatformException catch (e) {
      return AssetArchiveExportResult.failed(
        assetCount: assetCount,
        message: '保存失败：${e.code} - ${e.message}',
      );
    } catch (e) {
      return AssetArchiveExportResult.failed(
        assetCount: assetCount,
        message: '保存失败：$e',
      );
    }
  }

  static Future<AssetArchiveExportResult> _exportToAndroidDownload(
    String csvString,
    String fileName,
    int assetCount,
  ) async {
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final filePath = '${downloadDir.path}/$fileName';
        await File(filePath).writeAsString(csvString);
        return AssetArchiveExportResult.success(
          assetCount: assetCount,
          message: '已保存到下载目录：$fileName',
        );
      }

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/$fileName';
      await File(tempFilePath).writeAsString(csvString);
      return AssetArchiveExportResult.success(
        assetCount: assetCount,
        message: '已保存到临时目录：$fileName\n路径：$tempFilePath',
      );
    } catch (e) {
      return AssetArchiveExportResult.failed(
        assetCount: assetCount,
        message: '保存失败，请检查存储权限：$e',
      );
    }
  }

  static Future<String?> _saveCsv(String csvString, String fileName) {
    return FilePicker.platform.saveFile(
      dialogTitle: '保存 CSV 文件',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: Uint8List.fromList(utf8.encode(csvString)),
    );
  }
}

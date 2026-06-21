import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;

class AssetExportResult {
  final String? savePath;
  final String? errorMessage;
  final bool isCanceled;
  final bool isUnsupported;

  const AssetExportResult._({
    this.savePath,
    this.errorMessage,
    this.isCanceled = false,
    this.isUnsupported = false,
  });

  const AssetExportResult.saved(String savePath) : this._(savePath: savePath);

  const AssetExportResult.canceled() : this._(isCanceled: true);

  const AssetExportResult.unsupported()
    : this._(isUnsupported: true, errorMessage: '当前平台不支持导出');

  const AssetExportResult.failed(String message)
    : this._(errorMessage: message);

  bool get isSaved => savePath != null && savePath!.isNotEmpty;
}

class AssetExportService {
  static Future<AssetExportResult> saveCsv({
    required String csvString,
    required String defaultFileName,
  }) async {
    if (kIsWeb) {
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', defaultFileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      return AssetExportResult.saved(defaultFileName);
    }

    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: '保存 CSV 文件',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList(utf8.encode(csvString)),
      );

      if (savePath == null || savePath.isEmpty) {
        return const AssetExportResult.canceled();
      }

      return AssetExportResult.saved(savePath);
    } on PlatformException catch (e) {
      return AssetExportResult.failed('保存失败：${e.code} - ${e.message}');
    } catch (e) {
      return AssetExportResult.failed('保存失败：$e');
    }
  }
}

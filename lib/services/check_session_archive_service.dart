import 'dart:convert';

import 'package:csv/csv.dart';

import '../models/asset_category.dart';
import '../providers/check_provider.dart';

class CheckSessionArchiveService {
  const CheckSessionArchiveService._();

  static Future<String> exportCsv({
    required CheckProvider provider,
    required Iterable<String> sessionIds,
  }) async {
    final sessionsById = {
      for (final session in provider.sessions) session.id: session,
    };
    final csvRows = <List<dynamic>>[
      [
        'session_id',
        'session_name',
        'session_status',
        'session_created_at',
        'item_id',
        'asset_id',
        'asset_name',
        'purchase_price',
        'category',
        'asset_status',
        'confirmed_at',
      ],
    ];

    for (final sessionId in sessionIds) {
      final session = sessionsById[sessionId];
      if (session == null) continue;

      final items = await provider.getItems(sessionId);
      for (final item in items) {
        final snapshot = item.snapshotData;
        csvRows.add([
          session.id,
          session.name,
          session.status,
          session.createdAt,
          item.id,
          item.assetId,
          snapshot['assetName'] ?? '',
          snapshot['purchasePrice'] ?? '',
          AssetCategory.normalize(snapshot['category']?.toString() ?? ''),
          snapshot['status'] ?? '',
          item.confirmedAt ?? '',
        ]);
      }
    }

    return const ListToCsvConverter().convert(csvRows);
  }

  static String encodeExportData(Map<String, dynamic> data) {
    final session = data['session'] as Map<String, dynamic>;
    final items = data['items'] as List;
    final csvRows = <List<dynamic>>[
      [
        'session_id',
        'session_name',
        'session_status',
        'session_created_at',
        'item_id',
        'asset_id',
        'asset_name',
        'purchase_price',
        'category',
        'asset_status',
        'confirmed_at',
      ],
    ];

    for (final item in items) {
      final itemMap = item as Map<String, dynamic>;
      final snapshot = jsonDecode(itemMap['asset_snapshot'] as String);
      csvRows.add([
        session['id'],
        session['name'],
        session['status'],
        session['created_at'],
        itemMap['id'],
        itemMap['asset_id'],
        snapshot['assetName'] ?? '',
        snapshot['purchasePrice'] ?? '',
        AssetCategory.normalize(snapshot['category']?.toString() ?? ''),
        snapshot['status'] ?? '',
        itemMap['confirmed_at'] ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(csvRows);
  }

  static Future<int> importCsv({
    required CheckProvider provider,
    required String csvString,
  }) async {
    final sessions = parseCsv(csvString);
    var importedCount = 0;

    for (final session in sessions) {
      final newSession = await provider.createSession('${session.name}（导入）');

      for (final item in session.items) {
        final created = await provider.addItem(
          sessionId: newSession.id,
          assetId: item.assetId,
          assetSnapshot: jsonEncode(item.snapshot),
        );
        if (item.isConfirmed) {
          await provider.confirmItem(created.id);
        }
      }

      importedCount++;
    }

    return importedCount;
  }

  static List<CheckSessionCsvImport> parseCsv(String csvString) {
    final normalizedCsv = csvString
        .trim()
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final csvRows = const CsvToListConverter(eol: '\n').convert(normalizedCsv);
    if (csvRows.length < 2) {
      throw const FormatException('CSV 文件为空或格式不正确');
    }

    final header = csvRows[0].map((e) => e.toString().toLowerCase()).toList();
    final fieldIndex = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      fieldIndex[header[i]] = i;
    }

    for (final field in ['session_id', 'session_name', 'asset_id']) {
      if (!fieldIndex.containsKey(field)) {
        throw FormatException('CSV 缺少必要字段：$field');
      }
    }

    final assetStatusKey = fieldIndex.containsKey('asset_status')
        ? 'asset_status'
        : (fieldIndex.containsKey('status') ? 'status' : null);
    final groupedRows = <String, List<List<dynamic>>>{};
    final sessionNames = <String, String>{};

    for (var i = 1; i < csvRows.length; i++) {
      final row = csvRows[i];
      final sid = _cell(row, fieldIndex['session_id']);
      if (sid.isEmpty) continue;

      groupedRows.putIfAbsent(sid, () => []).add(row);
      sessionNames[sid] = _cell(row, fieldIndex['session_name']);
    }

    return groupedRows.entries.map((entry) {
      final items = entry.value.map((row) {
        final status = _cell(row, fieldIndex[assetStatusKey]);
        final category = AssetCategory.normalize(
          _cell(row, fieldIndex['category']),
        );
        final purchasePrice = double.tryParse(
          _cell(row, fieldIndex['purchase_price']),
        );
        final snapshot = <String, dynamic>{
          'id': _cell(row, fieldIndex['asset_id']),
          'assetName': _cell(row, fieldIndex['asset_name']),
          'purchasePrice': purchasePrice,
          'category': category,
        };
        if (status.isNotEmpty) {
          snapshot['status'] = int.tryParse(status);
        }

        return CheckSessionCsvItem(
          assetId: _cell(row, fieldIndex['asset_id']),
          snapshot: snapshot,
          isConfirmed:
              int.tryParse(_cell(row, fieldIndex['confirmed_at'])) != null,
        );
      }).toList();

      return CheckSessionCsvImport(
        name: sessionNames[entry.key]?.isNotEmpty == true
            ? sessionNames[entry.key]!
            : '未命名',
        items: items,
      );
    }).toList();
  }

  static Future<void> importJson({
    required CheckProvider provider,
    required String jsonString,
  }) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    if (!data.containsKey('session') || !data.containsKey('items')) {
      throw const FormatException('文件格式不正确');
    }
    await provider.importSession(data);
  }

  static String _cell(List<dynamic> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index]?.toString() ?? '';
  }
}

class CheckSessionCsvImport {
  final String name;
  final List<CheckSessionCsvItem> items;

  const CheckSessionCsvImport({required this.name, required this.items});
}

class CheckSessionCsvItem {
  final String assetId;
  final Map<String, dynamic> snapshot;
  final bool isConfirmed;

  const CheckSessionCsvItem({
    required this.assetId,
    required this.snapshot,
    required this.isConfirmed,
  });
}

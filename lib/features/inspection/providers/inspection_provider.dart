import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/inspection_db.dart';
import '../models/company_asset.dart';
import '../models/company_check_session.dart';
import '../models/company_check_item.dart';
import '../services/webdav_config.dart';
import '../services/webdav_service.dart';

class InspectionProvider extends ChangeNotifier {
  final InspectionDb _db = InspectionDb();

  List<CompanyCheckSession> _sessions = [];
  List<CompanyCheckSession> get sessions => _sessions;

  // ==================== Session CRUD ====================

  Future<void> loadSessions() async {
    _sessions = await _db.getAllSessions();
    notifyListeners();
  }

  Future<CompanyCheckSession> createSession(String name) async {
    final session = CompanyCheckSession.create(name: name);
    await _db.insertSession(session);
    await loadSessions();
    return session;
  }

  Future<void> renameSession(String id, String name) async {
    await _db.updateSessionName(id, name);
    await loadSessions();
  }

  Future<void> completeSession(String id) async {
    await _db.updateSessionStatus(id, 1);
    await loadSessions();
  }

  Future<void> deleteSession(String id) async {
    await _db.deleteSession(id);
    await loadSessions();
  }

  // ==================== Item CRUD ====================

  Future<List<CompanyCheckItem>> getItems(String sessionId) async {
    return await _db.getItems(sessionId);
  }

  Future<CompanyCheckItem> addItem({
    required String sessionId,
    required String assetCode,
    required String assetSnapshot,
  }) async {
    final item = CompanyCheckItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      assetCode: assetCode,
      assetSnapshot: assetSnapshot,
    );
    await _db.insertItem(item);
    return item;
  }

  Future<void> confirmItem(String id) async {
    await _db.confirmItem(id);
  }

  Future<void> unconfirmItem(String id) async {
    await _db.unconfirmItem(id);
  }

  Future<void> deleteItem(String id) async {
    await _db.deleteItem(id);
  }

  // ==================== Asset Lookup ====================

  Future<CompanyAsset?> lookupAsset(String assetCode) async {
    return await _db.getAssetByCode(assetCode);
  }

  Future<int> getAssetCount() async {
    return await _db.getAssetCount();
  }

  // ==================== WebDAV Sync ====================

  Future<WebdavConfig?> _loadConfig() async {
    return await WebdavConfig.load();
  }

  /// 从 WebDAV 同步总资产到本地
  Future<int> syncAssetsFromWebDav() async {
    final config = await _loadConfig();
    if (config == null || config.serverUrl.isEmpty) {
      throw Exception('请先配置 WebDAV');
    }
    final service = WebdavService(config);
    final assets = await service.fetchAssetList();
    await _db.replaceAllAssets(assets);
    notifyListeners();
    return assets.length;
  }

  /// 上传会话到 WebDAV，返回分享码
  Future<String> uploadSession(String sessionId) async {
    final config = await _loadConfig();
    if (config == null || config.serverUrl.isEmpty) {
      throw Exception('请先配置 WebDAV');
    }

    final session = await _db.getSession(sessionId);
    if (session == null) throw Exception('会话不存在');

    final items = await _db.getItems(sessionId);
    final assetCodes = items.map((i) => i.assetCode).toList();
    final confirmedCodes =
        items.where((i) => i.isConfirmed).map((i) => i.assetCode).toList();

    final shareCode = WebdavService.generateShareCode();
    final data = {
      'name': session.name,
      'createdAt': session.createdAt,
      'assetCodes': assetCodes,
      'confirmedCodes': confirmedCodes,
    };

    final service = WebdavService(config);
    await service.uploadSession(shareCode, data);
    return shareCode;
  }

  /// 从 WebDAV 下载会话并导入
  Future<CompanyCheckSession> downloadAndImportSession(String shareCode) async {
    final config = await _loadConfig();
    if (config == null || config.serverUrl.isEmpty) {
      throw Exception('请先配置 WebDAV');
    }

    final service = WebdavService(config);
    final data = await service.downloadSession(shareCode);

    final name = data['name'] as String? ?? '导入的检查';
    final assetCodes = (data['assetCodes'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final confirmedCodes = (data['confirmedCodes'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        <String>{};

    // 创建新会话
    final session = await createSession('$name（导入）');

    // 为每个资产编码查找本地详情，创建检查项
    for (final code in assetCodes) {
      final asset = await _db.getAssetByCode(code);
      final snapshot =
          asset != null ? jsonEncode(asset.toSnapshotJson()) : jsonEncode({
            'assetCode': code,
            'assetName': '未知资产',
          });

      final item = await addItem(
        sessionId: session.id,
        assetCode: code,
        assetSnapshot: snapshot,
      );

      // 恢复确认状态
      if (confirmedCodes.contains(code)) {
        await confirmItem(item.id);
      }
    }

    return session;
  }
}

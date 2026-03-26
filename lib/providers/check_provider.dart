import 'package:flutter/foundation.dart';
import '../models/check_session.dart';
import '../services/local_db_service.dart';

class CheckProvider extends ChangeNotifier {
  List<CheckSession> _sessions = [];
  List<CheckSession> get sessions => _sessions;

  /// 加载所有检查任务
  Future<void> loadSessions() async {
    _sessions = await LocalDbService().getAllCheckSessions();
    notifyListeners();
  }

  /// 创建新检查任务
  Future<CheckSession> createSession(String name) async {
    final session = CheckSession.create(name: name);
    await LocalDbService().insertCheckSession(session);
    await loadSessions();
    return session;
  }

  /// 完成检查任务
  Future<void> completeSession(String id) async {
    await LocalDbService().updateCheckSessionStatus(id, 1);
    await loadSessions();
  }

  /// 删除检查任务
  Future<void> deleteSession(String id) async {
    await LocalDbService().deleteCheckSession(id);
    await loadSessions();
  }

  /// 获取检查项
  Future<List<CheckItem>> getItems(String sessionId) async {
    return await LocalDbService().getCheckItems(sessionId);
  }

  /// 添加检查项（扫码时调用）
  Future<CheckItem> addItem({
    required String sessionId,
    required String assetId,
    required String assetSnapshot,
  }) async {
    final item = CheckItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      assetId: assetId,
      assetSnapshot: assetSnapshot,
    );
    await LocalDbService().insertCheckItem(item);
    return item;
  }

  /// 确认检查项
  Future<void> confirmItem(String id) async {
    await LocalDbService().confirmCheckItem(id);
  }

  /// 取消确认检查项
  Future<void> unconfirmItem(String id) async {
    final db = LocalDbService().db;
    await db.update(
      'check_items',
      {'confirmed_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除检查项
  Future<void> deleteItem(String id) async {
    await LocalDbService().deleteCheckItem(id);
  }

  /// 导出检查任务
  Future<Map<String, dynamic>> exportSession(String sessionId) async {
    return await LocalDbService().exportCheckSession(sessionId);
  }

  /// 导入检查任务
  Future<void> importSession(Map<String, dynamic> data) async {
    await LocalDbService().importCheckSession(data);
    await loadSessions();
  }
}

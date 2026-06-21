import 'dart:io';
import 'dart:developer';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';
import '../models/asset_category.dart';
import '../models/check_session.dart';
import 'local_db_schema.dart';

/// 本地数据库服务类 V2.0 - 单例模式
/// 负责管理 sqflite 数据库实例和提供 CRUD 操作
class LocalDbService {
  // 单例模式
  LocalDbService._internal();
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;

  /// sqflite 数据库实例
  Database? _db;

  /// 获取数据库实例
  Database get db {
    if (_db == null) {
      throw StateError('LocalDbService 未初始化，请先调用 init() 方法');
    }
    return _db!;
  }

  /// 初始化本地数据库
  /// 必须在 app 启动时调用，且在 WidgetsFlutterBinding.ensureInitialized() 之后
  Future<void> init() async {
    // 获取数据库文件路径
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, LocalDbSchema.databaseName);

    // 打开数据库并创建表
    _db = await openDatabase(
      path,
      version: LocalDbSchema.version,
      onCreate: LocalDbSchema.create,
      onUpgrade: LocalDbSchema.upgrade,
    );
  }

  /// 获取所有资产
  Future<List<Asset>> getAllAssets() async {
    final List<Map<String, dynamic>> maps = await db.query('assets');
    log('========== [LocalDb] 查库完成，获取到资产总数：${maps.length} ==========');
    return maps.map((map) => Asset.fromMap(map)).toList();
  }

  /// 保存或更新单个资产
  /// 如果资产的 id 已存在则更新，否则插入
  Future<void> saveAsset(Asset asset) async {
    // 绝对防御：如果 id 为空，强行生成一个 UUID v4
    if (asset.id.isEmpty) {
      asset.id = const Uuid().v4();
    }

    await db.insert(
      'assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量保存资产
  /// 用于批量导入场景（不查重，直接插入）
  Future<void> saveAllAssets(List<Asset> assets) async {
    // 绝对防御：为所有缺少 UUID 的资产生成 UUID v4
    final uuid = const Uuid();
    for (var asset in assets) {
      if (asset.id.isEmpty) {
        asset.id = uuid.v4();
      }
    }

    final batch = db.batch();
    for (var asset in assets) {
      batch.insert(
        'assets',
        asset.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// 导入资产数据（真正的 Upsert：查重并覆盖）
  ///
  /// 严格按照 UUID 字段 id 查重，如果存在则覆盖更新。
  /// 返回 Record 类型，包含 inserted 和 updated 两个整数字段。
  Future<(int inserted, int updated)> importAssetsWithUpsert(
    List<Asset> parsedAssets,
  ) async {
    if (parsedAssets.isEmpty) return (0, 0);

    int insertedCount = 0;
    int updatedCount = 0;

    // 绝对防御：为所有缺少 UUID 的资产生成 UUID v4
    final uuid = const Uuid();
    for (var asset in parsedAssets) {
      if (asset.id.isEmpty) {
        asset.id = uuid.v4();
      }
    }

    // 性能优化：一次性批量查询所有导入资产的 ID
    final allIds = parsedAssets.map((asset) => asset.id).toList();
    final placeholders = List.filled(allIds.length, '?').join(',');
    final existingMaps = await db.query(
      'assets',
      columns: ['id'],
      where: 'id IN ($placeholders)',
      whereArgs: allIds,
    );

    // 在内存中用 Set 判断哪些已存在
    final existingIds = existingMaps.map((map) => map['id'] as String).toSet();

    // 分别构建 insert 和 update 的 batch 操作
    final batch = db.batch();
    for (var importedAsset in parsedAssets) {
      if (existingIds.contains(importedAsset.id)) {
        // 更新现有记录
        batch.update(
          'assets',
          importedAsset.toMap(),
          where: 'id = ?',
          whereArgs: [importedAsset.id],
        );
        updatedCount++;
      } else {
        // 插入新记录
        batch.insert('assets', importedAsset.toMap());
        insertedCount++;
      }
    }

    // 统一 commit
    await batch.commit(noResult: true);

    return (insertedCount, updatedCount);
  }

  /// 通过主键（UUID）删除资产
  Future<void> deleteAsset(String id) async {
    await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  /// 删除资产并物理删除关联的文件
  /// 先根据 ID 查询资产，如果存在 avatarPath 则删除物理文件，最后删除数据库记录
  Future<void> deleteAssetWithFile(String id) async {
    // 先查询资产
    final asset = await getAssetByUuid(id);

    if (asset != null) {
      // 如果存在头像路径，物理删除文件
      if (asset.avatarPath != null && asset.avatarPath!.isNotEmpty) {
        try {
          final file = File(asset.avatarPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // 文件删除失败不阻断数据库删除流程，仅打印日志
          log('========== [LocalDb] 删除文件失败：$e ==========');
        }
      }
    }

    // 删除数据库记录
    await deleteAsset(id);
  }

  /// 通过 UUID 删除资产（与 deleteAsset 相同，为了保持接口兼容）
  Future<void> deleteAssetByUuid(String uuid) async {
    await deleteAsset(uuid);
  }

  /// 删除所有资产
  Future<void> deleteAllAssets() async {
    await db.delete('assets');
  }

  /// 用给定资产列表全量替换本地资产
  Future<void> replaceAllAssets(List<Asset> assets) async {
    final uuid = const Uuid();
    for (final asset in assets) {
      if (asset.id.isEmpty) {
        asset.id = uuid.v4();
      }
    }

    await db.transaction((txn) async {
      await txn.delete('assets');
      for (final asset in assets) {
        await txn.insert(
          'assets',
          asset.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 通过 UUID 查找资产
  Future<Asset?> getAssetByUuid(String uuid) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'assets',
      where: 'id = ?',
      whereArgs: [uuid],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Asset.fromMap(maps.first);
  }

  /// 通过字符串 ID 查找资产（封装供 UI 层调用）
  Future<Asset?> getAssetByStringId(String stringId) async {
    return await getAssetByUuid(stringId);
  }

  /// V2.1: 通过 ID 查找资产（扫码去重专用）
  Future<Asset?> getAssetById(String id) async {
    return await getAssetByUuid(id);
  }

  /// 通过 UUID 列表批量查找资产
  /// 返回一个 Map，key 为 uuid 字符串，value 为 Asset 对象，便于快速查重
  Future<Map<String, Asset>> getAssetsByUuids(List<String> uuids) async {
    if (uuids.isEmpty) return {};

    // 构建占位符
    final placeholders = List.filled(uuids.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      'assets',
      where: 'id IN ($placeholders)',
      whereArgs: uuids,
    );

    final result = <String, Asset>{};
    for (final map in maps) {
      final asset = Asset.fromMap(map);
      result[asset.id] = asset;
    }
    return result;
  }

  /// 获取资产总数
  Future<int> getAssetCount() async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM assets');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 同步指定标签的资产到云端
  /// 根据标签筛选资产并标记为已同步
  Future<void> syncAssetsWithTag(String tag) async {
    // 由于 SQLite 不支持直接查询 JSON 数组中的元素，
    // 我们需要先获取所有资产，然后在内存中筛选
    final allAssets = await getAllAssets();
    final assetsToSync = allAssets
        .where((asset) => asset.tags.contains(tag))
        .toList();

    // 这里可以添加云端同步逻辑
    // 当前仅作为接口保留
    log(
      '========== [LocalDb] 同步带标签 "$tag" 的资产：${assetsToSync.length} 条 ==========',
    );
  }

  /// 删除分类时将相关资产归入未分类，避免误删用户资产。
  Future<void> deleteCategoryAndCleanTags(String category) async {
    final normalizedCategory = AssetCategory.normalize(category);
    if (normalizedCategory == AssetCategory.uncategorized) return;

    await db.update(
      'assets',
      {'category': AssetCategory.uncategorized},
      where: 'category = ?',
      whereArgs: [normalizedCategory],
    );
  }

  // === 检查任务 CRUD ===

  Future<CheckSession> insertCheckSession(CheckSession session) async {
    final db = this.db;
    await db.insert('check_sessions', session.toMap());
    return session;
  }

  Future<List<CheckSession>> getAllCheckSessions() async {
    final db = this.db;
    final maps = await db.query('check_sessions', orderBy: 'created_at DESC');
    return maps.map((m) => CheckSession.fromMap(m)).toList();
  }

  Future<CheckSession?> getCheckSession(String id) async {
    final db = this.db;
    final maps = await db.query(
      'check_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CheckSession.fromMap(maps.first);
  }

  Future<void> updateCheckSessionStatus(String id, int status) async {
    final db = this.db;
    await db.update(
      'check_sessions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateCheckSessionName(String id, String name) async {
    final db = this.db;
    await db.update(
      'check_sessions',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCheckSession(String id) async {
    final db = this.db;
    await db.delete('check_items', where: 'session_id = ?', whereArgs: [id]);
    await db.delete('check_sessions', where: 'id = ?', whereArgs: [id]);
  }

  // === 检查项 CRUD ===

  Future<CheckItem> insertCheckItem(CheckItem item) async {
    final db = this.db;
    await db.insert('check_items', item.toMap());
    return item;
  }

  Future<List<CheckItem>> getCheckItems(String sessionId) async {
    final db = this.db;
    final maps = await db.query(
      'check_items',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    return maps.map((m) => CheckItem.fromMap(m)).toList();
  }

  Future<void> confirmCheckItem(String id) async {
    final db = this.db;
    await db.update(
      'check_items',
      {'confirmed_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCheckItem(String id) async {
    final db = this.db;
    await db.delete('check_items', where: 'id = ?', whereArgs: [id]);
  }

  /// 检查项导出为 JSON
  Future<Map<String, dynamic>> exportCheckSession(String sessionId) async {
    final session = await getCheckSession(sessionId);
    if (session == null) throw Exception('检查任务不存在');
    final items = await getCheckItems(sessionId);
    return {
      'session': session.toMap(),
      'items': items.map((i) => i.toMap()).toList(),
    };
  }

  /// 从 JSON 导入检查项
  Future<void> importCheckSession(Map<String, dynamic> data) async {
    final session = CheckSession.fromMap(data['session']);
    final items = (data['items'] as List)
        .map((i) => CheckItem.fromMap(i))
        .toList();
    await insertCheckSession(session);
    for (final item in items) {
      await insertCheckItem(item);
    }
  }

  /// 关闭数据库连接
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

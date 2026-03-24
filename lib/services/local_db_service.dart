import 'dart:io';
import 'dart:developer';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';

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
    final path = join(databasesPath, 'daily_price.db');

    // 打开数据库并创建表
    _db = await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 数据库创建回调 - V3.0: 包含头像引擎新字段
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE assets(
        id TEXT PRIMARY KEY,
        asset_name TEXT NOT NULL,
        purchase_price REAL,
        purchase_date INTEGER NOT NULL,
        is_pinned INTEGER DEFAULT 0,
        category TEXT DEFAULT '未分类',
        tags TEXT DEFAULT '[]',
        created_at INTEGER NOT NULL,
        status INTEGER DEFAULT 0,
        expected_lifespan_days INTEGER,
        expire_date INTEGER,
        sold_price REAL,
        sold_date INTEGER,
        avatar_path TEXT,
        avatar_bg_color INTEGER,
        avatar_text TEXT,
        avatar_icon_code_point INTEGER,
        exclude_from_total INTEGER DEFAULT 0,
        exclude_from_daily INTEGER DEFAULT 0,
        ownership_type TEXT DEFAULT 'buyout',
        renewals TEXT DEFAULT '[]'
      )
    ''');
  }

  /// 数据库升级回调
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // V2 -> V3: 添加头像引擎字段 (avatar_bg_color, avatar_text, avatar_icon_code_point)
    if (oldVersion < 3) {
      await _addAvatarV3Fields(db);
    }

    // V5 -> V6: 自定义分类 + ownership_type 升级
    if (oldVersion < 6) {
      // 先检查列是否存在
      final columns = await db.rawQuery('PRAGMA table_info(assets)');
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      // 新增 ownership_type 列（如果不存在）
      if (!columnNames.contains('ownership_type')) {
        await db.execute(
          "ALTER TABLE assets ADD COLUMN ownership_type TEXT DEFAULT 'buyout'",
        );
      }

      // 将 subscription 类别的资产设置 ownership_type 为 'subscription'
      await db.execute(
        "UPDATE assets SET ownership_type = 'subscription' WHERE category = 'subscription'",
      );

      // 将所有旧分类统一改为 '未分类'
      await db.execute(
        "UPDATE assets SET category = '未分类' WHERE category IN ('physical', 'virtual', 'subscription')",
      );

      log('========== [LocalDb] V6 自定义分类 + ownership_type 升级完成 ==========');
    }

    // V6 -> V7: 添加续费记录字段
    if (oldVersion < 7) {
      // 先检查列是否存在
      final columns = await db.rawQuery('PRAGMA table_info(assets)');
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      // 新增 renewals 列（如果不存在）
      if (!columnNames.contains('renewals')) {
        await db.execute(
          "ALTER TABLE assets ADD COLUMN renewals TEXT DEFAULT '[]'",
        );
      }
      log('========== [LocalDb] V7 续费记录字段升级完成 ==========');
    }
  }

  /// V3.0: 使用 ALTER TABLE 为 assets 表添加头像引擎新字段
  /// 关键：使用 ALTER TABLE 避免老数据丢失
  Future<void> _addAvatarV3Fields(Database db) async {
    // 检查 avatar_bg_color 字段是否存在
    final columns = await db.rawQuery('PRAGMA table_info(assets)');
    final columnNames = columns.map((c) => c['name'] as String).toSet();

    // 添加 avatar_bg_color 字段 (存储 16进制颜色 int 值)
    if (!columnNames.contains('avatar_bg_color')) {
      await db.execute('ALTER TABLE assets ADD COLUMN avatar_bg_color INTEGER');
    }

    // 添加 avatar_text 字段 (用户自定义的1-2个字符)
    if (!columnNames.contains('avatar_text')) {
      await db.execute('ALTER TABLE assets ADD COLUMN avatar_text TEXT');
    }

    // 添加 avatar_icon_code_point 字段 (Material Icon 的 codePoint)
    if (!columnNames.contains('avatar_icon_code_point')) {
      await db.execute(
        'ALTER TABLE assets ADD COLUMN avatar_icon_code_point INTEGER',
      );
    }

    log('========== [LocalDb] V3.0 头像引擎字段升级完成 ==========');
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

  /// 删除分类并清理相关标签
  /// 删除指定分类的所有资产
  Future<void> deleteCategoryAndCleanTags(String category) async {
    await db.delete('assets', where: 'category = ?', whereArgs: [category]);
  }

  /// 关闭数据库连接
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

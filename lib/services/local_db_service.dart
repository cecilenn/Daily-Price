import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';

/// 本地数据库服务类 - 单例模式
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
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE assets(
            id TEXT PRIMARY KEY,
            userId TEXT,
            assetName TEXT NOT NULL,
            purchasePrice REAL NOT NULL,
            expectedLifespanDays INTEGER NOT NULL,
            purchaseDate INTEGER NOT NULL,
            isPinned INTEGER DEFAULT 0,
            isSold INTEGER DEFAULT 0,
            soldPrice REAL,
            soldDate INTEGER,
            category TEXT DEFAULT 'physical',
            expireDate INTEGER,
            renewalHistoryJson TEXT DEFAULT '[]',
            tags TEXT DEFAULT '[]',
            createdAt INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// 获取所有资产
  Future<List<Asset>> getAllAssets() async {
    final List<Map<String, dynamic>> maps = await db.query('assets');
    print('========== [LocalDb] 查库完成，获取到资产总数: ${maps.length} ==========');
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
    int insertedCount = 0;
    int updatedCount = 0;

    // 绝对防御：为所有缺少 UUID 的资产生成 UUID v4
    final uuid = const Uuid();
    for (var asset in parsedAssets) {
      if (asset.id.isEmpty) {
        asset.id = uuid.v4();
      }
    }

    final batch = db.batch();
    for (var importedAsset in parsedAssets) {
      // 检查是否已存在
      final existing = await db.query(
        'assets',
        where: 'id = ?',
        whereArgs: [importedAsset.id],
        limit: 1,
      );

      if (existing.isNotEmpty) {
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
    await batch.commit(noResult: true);

    return (insertedCount, updatedCount);
  }

  /// 通过主键（UUID）删除资产
  Future<void> deleteAsset(String id) async {
    await db.delete('assets', where: 'id = ?', whereArgs: [id]);
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
    print(
      '========== [LocalDb] 同步带标签 "$tag" 的资产: ${assetsToSync.length} 条 ==========',
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

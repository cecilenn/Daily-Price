import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';

/// 本地数据库服务类 - 单例模式
/// 负责管理 Isar 数据库实例和提供 CRUD 操作
class LocalDbService {
  // 单例模式
  LocalDbService._internal();
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;

  /// Isar 数据库实例
  Isar? _isar;

  /// 获取 Isar 实例
  Isar get isar {
    if (_isar == null) {
      throw StateError('LocalDbService 未初始化，请先调用 init() 方法');
    }
    return _isar!;
  }

  /// 初始化本地数据库
  /// 必须在 app 启动时调用，且在 WidgetsFlutterBinding.ensureInitialized() 之后
  Future<void> init() async {
    // 获取应用文档目录
    final dir = await getApplicationDocumentsDirectory();
    
    // 打开 Isar 数据库
    _isar = await Isar.open(
      [AssetSchema],
      directory: dir.path,
      inspector: true, // 开发环境启用检查器
    );
  }

  /// 获取所有资产
  Future<List<Asset>> getAllAssets() async {
    final assets = await isar.assets.where().findAll();
    print('========== [LocalDb] 查库完成，获取到资产总数: ${assets.length} ==========');
    return assets;
  }

  /// 保存或更新单个资产
  /// 如果资产的 isarId 已存在则更新，否则插入
  Future<void> saveAsset(Asset asset) async {
    // 绝对防御：如果字符串 id 为空，强行生成一个 UUID v4
    if (asset.id == null || asset.id!.trim().isEmpty) {
      asset.id = const Uuid().v4();
    }
    
    await isar.writeTxn(() async {
      await isar.assets.put(asset);
    });
  }

  /// 批量保存资产
  /// 用于批量导入场景（不查重，直接插入）
  Future<void> saveAllAssets(List<Asset> assets) async {
    // 绝对防御：为所有缺少 UUID 的资产生成 UUID v4
    final uuid = const Uuid();
    for (var asset in assets) {
      if (asset.id == null || asset.id!.trim().isEmpty) {
        asset.id = uuid.v4();
      }
    }
    
    await isar.writeTxn(() async {
      await isar.assets.putAll(assets);
    });
  }

  /// 导入资产数据（真正的 Upsert：查重并覆盖）
  /// 
  /// 严格按照 UUID 字段 id 查重，如果存在则继承 isarId 实现覆盖更新。
  /// 返回 Record 类型，包含 inserted 和 updated 两个整数字段。
  Future<(int inserted, int updated)> importAssetsWithUpsert(List<Asset> parsedAssets) async {
    int insertedCount = 0;
    int updatedCount = 0;

    // 绝对防御：为所有缺少 UUID 的资产生成 UUID v4
    final uuid = const Uuid();
    for (var asset in parsedAssets) {
      if (asset.id == null || asset.id!.trim().isEmpty) {
        asset.id = uuid.v4();
      }
    }

    await isar.writeTxn(() async {
      for (var importedAsset in parsedAssets) {
        // 1. 用字符串 UUID 去本地查重
        final existing = await isar.assets.filter().idEqualTo(importedAsset.id).findFirst();
        
        // 2. 如果存在，必须把本地的 isarId 赋给导入的对象！
        if (existing != null) {
          importedAsset.isarId = existing.isarId;
          await isar.assets.put(importedAsset);
          updatedCount++;
        } else {
          // 3. 不存在则作为新资产插入
          await isar.assets.put(importedAsset);
          insertedCount++;
        }
      }
    });

    return (insertedCount, updatedCount);
  }

  /// 通过 Isar 主键删除资产
  Future<void> deleteAsset(int isarId) async {
    await isar.writeTxn(() async {
      await isar.assets.delete(isarId);
    });
  }

  /// 通过 UUID 删除资产
  Future<void> deleteAssetByUuid(String uuid) async {
    await isar.writeTxn(() async {
      await isar.assets.where().idEqualTo(uuid).deleteFirst();
    });
  }

  /// 删除所有资产
  Future<void> deleteAllAssets() async {
    await isar.writeTxn(() async {
      await isar.assets.clear();
    });
  }

  /// 通过 UUID 查找资产
  Future<Asset?> getAssetByUuid(String uuid) async {
    return await isar.assets.where().idEqualTo(uuid).findFirst();
  }

  /// 通过字符串 ID 查找资产（封装供 UI 层调用）
  Future<Asset?> getAssetByStringId(String stringId) async {
    return await isar.assets.filter().idEqualTo(stringId).findFirst();
  }

  /// 通过 UUID 列表批量查找资产
  /// 返回一个 Map，key 为 uuid 字符串，value 为 Asset 对象，便于快速查重
  Future<Map<String, Asset>> getAssetsByUuids(List<String> uuids) async {
    if (uuids.isEmpty) return {};
    final assets = await isar.assets
        .where()
        .anyOf(uuids, (q, uuid) => q.idEqualTo(uuid))
        .findAll();
    final result = <String, Asset>{};
    for (final asset in assets) {
      if (asset.id != null) {
        result[asset.id!] = asset;
      }
    }
    return result;
  }

  /// 获取资产总数
  Future<int> getAssetCount() async {
    return await isar.assets.count();
  }

  /// 关闭数据库连接
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
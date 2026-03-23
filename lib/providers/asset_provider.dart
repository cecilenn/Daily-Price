import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/local_db_service.dart';

class AssetProvider with ChangeNotifier {
  List<Asset> _assets = [];
  bool _isLoading = false;
  String? _error;

  List<Asset> get assets => _assets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 启动时加载全部资产
  Future<void> loadAssets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assets = await LocalDbService().getAllAssets();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 保存单个资产（新增或更新）
  Future<void> saveAsset(Asset asset) async {
    await LocalDbService().saveAsset(asset);
    final index = _assets.indexWhere((a) => a.id == asset.id);
    if (index >= 0) {
      _assets[index] = asset;
    } else {
      _assets.add(asset);
    }
    notifyListeners();
  }

  /// 删除资产（含物理文件）
  Future<void> deleteAsset(String id) async {
    await LocalDbService().deleteAssetWithFile(id);
    _assets.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  /// 批量导入（upsert）
  Future<(int inserted, int updated)> importAssets(
    List<Asset> parsedAssets,
  ) async {
    final result = await LocalDbService().importAssetsWithUpsert(parsedAssets);
    await loadAssets(); // 重新加载以同步数据
    return result;
  }

  /// 删除所有资产
  Future<void> deleteAllAssets() async {
    await LocalDbService().deleteAllAssets();
    _assets.clear();
    notifyListeners();
  }

  /// 切换置顶状态
  Future<void> togglePinned(Asset asset) async {
    final updated = asset.copyWith(isPinned: asset.isPinned == 0 ? 1 : 0);
    await saveAsset(updated);
  }
}

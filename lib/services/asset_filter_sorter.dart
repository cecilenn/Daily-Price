import '../models/asset.dart';

/// 资产过滤与排序器
///
/// 负责根据分栏和排序规则过滤并排序资产列表
class AssetFilterSorter {
  /// 过滤并排序资产列表
  ///
  /// 参数：
  /// - assets: 全部资产列表
  /// - category: 当前分栏
  ///   - 'all' → 全部
  ///   - 'pinned' → 置顶
  ///   - 'physical'/'virtual'/'subscription' → 按分类
  ///   - 'custom_xxx' → 按自定义标签
  /// - sortBy: 排序字段 ('created_at', 'name', 'purchase_date', 'price')
  /// - ascending: 是否升序
  ///
  /// 排序规则：
  /// - 第一优先级：置顶（isPinned=1 的排前面）
  /// - 第二优先级：用户选择的排序字段
  static List<Asset> filterAndSort({
    required List<Asset> assets,
    required String category,
    required String sortBy,
    required bool ascending,
  }) {
    List<Asset> filtered;

    if (category == 'all') {
      filtered = List.from(assets);
    } else if (category == 'pinned') {
      filtered = assets.where((a) => a.isPinned == 1).toList();
    } else if (category.startsWith('custom_')) {
      filtered = assets.where((a) => a.tags.contains(category)).toList();
    } else {
      filtered = assets.where((a) => a.category == category).toList();
    }

    // V2.0 置顶优先级排序：isPinned 永远排第一
    filtered.sort((a, b) {
      // 第一排序规则：置顶优先
      if (a.isPinned != b.isPinned) {
        return b.isPinned - a.isPinned;
      }

      // 第二排序规则：用户选择的排序字段
      int result;
      switch (sortBy) {
        case 'name':
          result = a.assetName.compareTo(b.assetName);
          break;
        case 'purchase_date':
          result = a.purchaseDate.compareTo(b.purchaseDate);
          break;
        case 'price':
          final priceA = a.purchasePrice ?? 0;
          final priceB = b.purchasePrice ?? 0;
          result = priceA.compareTo(priceB);
          break;
        case 'created_at':
        default:
          result = a.createdAt.compareTo(b.createdAt);
      }
      return ascending ? result : -result;
    });

    return filtered;
  }
}

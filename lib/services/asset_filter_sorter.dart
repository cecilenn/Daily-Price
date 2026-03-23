import 'package:flutter/material.dart';
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
  /// - sortBy: 排序字段 ('created_at', 'name', 'price', 'dailyCost', 'daysUsed')
  /// - ascending: 是否升序
  /// - searchQuery: 搜索关键字（对 assetName 模糊匹配，不区分大小写）
  /// - statusFilter: 状态筛选（null=全部，0=服役中，1=已退役，2=已卖出）
  /// - categoryFilters: 分类筛选（资产的 category 在集合中即匹配）
  /// - tagFilters: 标签筛选（资产包含任一选中标签即匹配）
  /// - priceRange: 价格区间筛选
  ///
  /// 过滤顺序：分栏过滤 → 搜索过滤 → 状态过滤 → 分类过滤 → 标签过滤 → 价格过滤 → 排序
  ///
  /// 排序规则：
  /// - 第一优先级：置顶（isPinned=1 的排前面）
  /// - 第二优先级：用户选择的排序字段
  static List<Asset> filterAndSort({
    required List<Asset> assets,
    required String category,
    required String sortBy,
    required bool ascending,
    String? searchQuery,
    int? statusFilter,
    Set<String>? categoryFilters,
    Set<String>? tagFilters,
    RangeValues? priceRange,
  }) {
    List<Asset> filtered;

    // 1. 分栏过滤
    if (category == 'all') {
      filtered = List.from(assets);
    } else if (category == 'pinned') {
      filtered = assets.where((a) => a.isPinned == 1).toList();
    } else if (category.startsWith('custom_')) {
      filtered = assets.where((a) => a.tags.contains(category)).toList();
    } else {
      filtered = assets.where((a) => a.category == category).toList();
    }

    // 2. 搜索过滤
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered
          .where((a) => a.assetName.toLowerCase().contains(query))
          .toList();
    }

    // 3. 状态过滤
    if (statusFilter != null) {
      filtered = filtered.where((a) => a.status == statusFilter).toList();
    }

    // 4. 分类过滤
    if (categoryFilters != null && categoryFilters.isNotEmpty) {
      filtered = filtered
          .where((a) => categoryFilters.contains(a.category))
          .toList();
    }

    // 5. 标签过滤（资产包含任一选中标签即匹配）
    if (tagFilters != null && tagFilters.isNotEmpty) {
      filtered = filtered
          .where((a) => tagFilters.any((tag) => a.tags.contains(tag)))
          .toList();
    }

    // 6. 价格区间过滤
    if (priceRange != null) {
      filtered = filtered.where((a) {
        final price = a.purchasePrice ?? 0;
        return price >= priceRange.start && price <= priceRange.end;
      }).toList();
    }

    // 7. 排序
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
        case 'dailyCost':
          result = a.dailyCost.compareTo(b.dailyCost);
          break;
        case 'daysUsed':
          result = a.calculatedDays.compareTo(b.calculatedDays);
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

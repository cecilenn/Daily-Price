import '../models/asset.dart';

/// 统计计算器
///
/// 负责计算资产列表的全局统计数据
class StatsCalculator {
  /// 计算全局统计数据
  ///
  /// 返回 Map：
  /// - totalAssets: 总资产金额（已排除 excludeFromTotal）
  /// - dailyCost: 日均消费总额（已排除 excludeFromDaily）
  /// - activeCount: 服役中数量
  /// - retiredCount: 已退役数量
  /// - soldCount: 已卖出数量
  static Map<String, dynamic> calculate(List<Asset> assets) {
    double totalAssets = 0;
    double dailyCost = 0;
    int activeCount = 0;
    int retiredCount = 0;
    int soldCount = 0;

    for (final asset in assets) {
      // 统计状态
      if (asset.status == 0) {
        activeCount++;
      } else if (asset.status == 1) {
        retiredCount++;
      } else if (asset.status == 2) {
        soldCount++;
      }

      // 计算总资产（排除 excludeFromTotal）
      if (asset.excludeFromTotal == 0 && asset.purchasePrice != null) {
        totalAssets += asset.purchasePrice!;
      }

      // 计算日均消费（排除 excludeFromDaily）
      if (asset.excludeFromDaily == 0) {
        dailyCost += asset.dailyCost;
      }
    }

    return {
      'totalAssets': totalAssets,
      'dailyCost': dailyCost,
      'activeCount': activeCount,
      'retiredCount': retiredCount,
      'soldCount': soldCount,
    };
  }
}

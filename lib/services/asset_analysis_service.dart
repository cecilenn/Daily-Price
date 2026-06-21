import '../models/asset.dart';

class AssetAnalysisService {
  const AssetAnalysisService._();

  static AssetAnalysis calculate(List<Asset> assets) {
    final status = AssetStatusDistribution.fromAssets(assets);
    final includedForTotal = assets.where((a) => a.excludeFromTotal == 0);
    final includedForDaily = assets.where((a) => a.excludeFromDaily == 0);

    final categories = <String, ({int count, double value})>{};
    for (final asset in includedForTotal) {
      final current = categories[asset.category] ?? (count: 0, value: 0.0);
      categories[asset.category] = (
        count: current.count + 1,
        value: current.value + (asset.purchasePrice ?? 0),
      );
    }

    final categoryBreakdown =
        categories.entries
            .where((entry) => entry.value.value > 0)
            .map(
              (entry) => AssetCategoryBreakdown(
                category: entry.key,
                count: entry.value.count,
                value: entry.value.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final totalCategoryValue = categoryBreakdown.fold(
      0.0,
      (sum, item) => sum + item.value,
    );

    final dailyCostTopAssets =
        includedForDaily.where((a) => a.dailyCost > 0).toList()
          ..sort((a, b) => b.dailyCost.compareTo(a.dailyCost));

    return AssetAnalysis(
      status: status,
      categoryBreakdown: categoryBreakdown,
      totalCategoryValue: totalCategoryValue,
      dailyCostTopAssets: dailyCostTopAssets.take(10).toList(),
      overview: AssetOverview.fromAssets(assets),
    );
  }
}

class AssetAnalysis {
  final AssetStatusDistribution status;
  final List<AssetCategoryBreakdown> categoryBreakdown;
  final double totalCategoryValue;
  final List<Asset> dailyCostTopAssets;
  final AssetOverview overview;

  const AssetAnalysis({
    required this.status,
    required this.categoryBreakdown,
    required this.totalCategoryValue,
    required this.dailyCostTopAssets,
    required this.overview,
  });
}

class AssetStatusDistribution {
  final int activeCount;
  final int retiredCount;
  final int soldCount;

  const AssetStatusDistribution({
    required this.activeCount,
    required this.retiredCount,
    required this.soldCount,
  });

  factory AssetStatusDistribution.fromAssets(List<Asset> assets) {
    var activeCount = 0;
    var retiredCount = 0;
    var soldCount = 0;

    for (final asset in assets) {
      switch (asset.status) {
        case 0:
          activeCount++;
          break;
        case 1:
          retiredCount++;
          break;
        case 2:
          soldCount++;
          break;
      }
    }

    return AssetStatusDistribution(
      activeCount: activeCount,
      retiredCount: retiredCount,
      soldCount: soldCount,
    );
  }
}

class AssetCategoryBreakdown {
  final String category;
  final int count;
  final double value;

  const AssetCategoryBreakdown({
    required this.category,
    required this.count,
    required this.value,
  });
}

class AssetOverview {
  final double totalAssets;
  final double dailyCost;
  final double averagePerItem;
  final Asset? mostExpensive;
  final Asset? longestLiving;

  const AssetOverview({
    required this.totalAssets,
    required this.dailyCost,
    required this.averagePerItem,
    required this.mostExpensive,
    required this.longestLiving,
  });

  factory AssetOverview.fromAssets(List<Asset> assets) {
    final includedForTotal = assets.where((a) => a.excludeFromTotal == 0);
    final includedForDaily = assets.where((a) => a.excludeFromDaily == 0);

    final totalAssets = includedForTotal.fold(
      0.0,
      (sum, asset) => sum + (asset.purchasePrice ?? 0),
    );
    final totalItemCount = includedForTotal.length;
    final averagePerItem = totalItemCount > 0
        ? totalAssets / totalItemCount
        : 0.0;
    final dailyCost = includedForDaily.fold(
      0.0,
      (sum, asset) => sum + asset.dailyCost,
    );

    Asset? mostExpensive;
    var maxPrice = 0.0;
    for (final asset in includedForTotal) {
      final price = asset.purchasePrice ?? 0;
      if (price > maxPrice) {
        maxPrice = price;
        mostExpensive = asset;
      }
    }

    Asset? longestLiving;
    var maxDays = 0;
    for (final asset in assets) {
      if (asset.status == 0 && asset.calculatedDays > maxDays) {
        maxDays = asset.calculatedDays;
        longestLiving = asset;
      }
    }

    return AssetOverview(
      totalAssets: totalAssets,
      dailyCost: dailyCost,
      averagePerItem: averagePerItem,
      mostExpensive: mostExpensive,
      longestLiving: longestLiving,
    );
  }
}

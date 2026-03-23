import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';

/// 分析页面 - 展示资产统计与分析
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  /// 格式化金额
  String _formatCurrency(double? amount) {
    if (amount == null) return '-';
    return '¥${amount.toStringAsFixed(2)}';
  }

  /// 格式化天数
  String _formatDays(int? days) {
    if (days == null) return '-';
    return Asset.formatDays(days, style: 'combined');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分析'), centerTitle: true, elevation: 0),
      body: Consumer<AssetProvider>(
        builder: (context, provider, child) {
          final assets = provider.assets;

          if (assets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '暂无分析数据',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '添加资产后即可查看分析',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 资产状态分布
                    _buildStatusDistribution(assets),
                    const SizedBox(height: 24),

                    // 资产分类占比
                    _buildCategoryPieChart(assets),
                    const SizedBox(height: 24),

                    // 日均消费 TOP 10
                    _buildDailyCostTop10(assets),
                    const SizedBox(height: 24),

                    // 总览数据
                    _buildOverviewData(assets),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建资产状态分布
  Widget _buildStatusDistribution(List<Asset> assets) {
    final activeCount = assets.where((a) => a.status == 0).length;
    final retiredCount = assets.where((a) => a.status == 1).length;
    final soldCount = assets.where((a) => a.status == 2).length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '资产状态分布',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    label: '服役中',
                    count: activeCount,
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    label: '已退役',
                    count: retiredCount,
                    color: Colors.grey,
                    icon: Icons.pause_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    label: '已卖出',
                    count: soldCount,
                    color: Colors.purple,
                    icon: Icons.money,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建状态卡片
  Widget _buildStatusCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// 构建资产分类占比饼图
  Widget _buildCategoryPieChart(List<Asset> assets) {
    // 按分类统计资产数量
    final physicalCount = assets.where((a) => a.category == 'physical').length;
    final virtualCount = assets.where((a) => a.category == 'virtual').length;
    final subscriptionCount = assets
        .where((a) => a.category == 'subscription')
        .length;

    // 按分类统计资产价值（排除 excludeFromTotal）
    final physicalValue = assets
        .where((a) => a.category == 'physical' && a.excludeFromTotal == 0)
        .fold(0.0, (sum, a) => sum + (a.purchasePrice ?? 0));
    final virtualValue = assets
        .where((a) => a.category == 'virtual' && a.excludeFromTotal == 0)
        .fold(0.0, (sum, a) => sum + (a.purchasePrice ?? 0));
    final subscriptionValue = assets
        .where((a) => a.category == 'subscription' && a.excludeFromTotal == 0)
        .fold(0.0, (sum, a) => sum + (a.purchasePrice ?? 0));

    final totalValue = physicalValue + virtualValue + subscriptionValue;

    if (totalValue == 0) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '资产分类占比',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('暂无价值数据')),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '资产分类占比',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          if (physicalValue > 0)
                            PieChartSectionData(
                              color: Colors.blue,
                              value: physicalValue,
                              title:
                                  '${(physicalValue / totalValue * 100).toStringAsFixed(1)}%',
                              radius: 60,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          if (virtualValue > 0)
                            PieChartSectionData(
                              color: Colors.orange,
                              value: virtualValue,
                              title:
                                  '${(virtualValue / totalValue * 100).toStringAsFixed(1)}%',
                              radius: 60,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          if (subscriptionValue > 0)
                            PieChartSectionData(
                              color: Colors.green,
                              value: subscriptionValue,
                              title:
                                  '${(subscriptionValue / totalValue * 100).toStringAsFixed(1)}%',
                              radius: 60,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      '实体资产',
                      Colors.blue,
                      physicalCount,
                      physicalValue,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      '虚拟资产',
                      Colors.orange,
                      virtualCount,
                      virtualValue,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      '限时资产',
                      Colors.green,
                      subscriptionCount,
                      subscriptionValue,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '总资产: ${_formatCurrency(totalValue)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图例项
  Widget _buildLegendItem(String label, Color color, int count, double value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              '$count 件 · ${_formatCurrency(value)}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建日均消费 TOP 10
  Widget _buildDailyCostTop10(List<Asset> assets) {
    // 按日均消费降序排序
    final sortedAssets = List<Asset>.from(assets)
      ..sort((a, b) => b.dailyCost.compareTo(a.dailyCost));

    // 取前 10 个
    final topAssets = sortedAssets.take(10).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '日均消费 TOP 10',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (topAssets.isEmpty)
              const Center(child: Text('暂无数据'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topAssets.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final asset = topAssets[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    title: Text(
                      asset.assetName,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatCurrency(asset.dailyCost),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 构建总览数据
  Widget _buildOverviewData(List<Asset> assets) {
    // 计算总资产（排除 excludeFromTotal）
    final totalAssets = assets
        .where((a) => a.excludeFromTotal == 0)
        .fold(0.0, (sum, a) => sum + (a.purchasePrice ?? 0));

    // 计算日均总消耗（排除 excludeFromDaily）
    final dailyCost = assets
        .where((a) => a.excludeFromDaily == 0)
        .fold(0.0, (sum, a) => sum + a.dailyCost);

    // 计算平均每件
    final avgPerItem = assets.isNotEmpty ? totalAssets / assets.length : 0.0;

    // 找到最贵资产
    Asset? mostExpensive;
    double maxPrice = 0;
    for (final asset in assets) {
      final price = asset.purchasePrice ?? 0;
      if (price > maxPrice) {
        maxPrice = price;
        mostExpensive = asset;
      }
    }

    // 找到最长寿资产（服役中）
    Asset? longestLiving;
    int maxDays = 0;
    for (final asset in assets) {
      if (asset.status == 0 && asset.calculatedDays > maxDays) {
        maxDays = asset.calculatedDays;
        longestLiving = asset;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '总览数据',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildOverviewRow('总资产', _formatCurrency(totalAssets)),
            _buildOverviewRow('日均总消耗', _formatCurrency(dailyCost)),
            _buildOverviewRow('平均每件', _formatCurrency(avgPerItem)),
            _buildOverviewRow('最贵资产', mostExpensive?.assetName ?? '-'),
            _buildOverviewRow(
              '最长寿资产',
              longestLiving != null
                  ? '${longestLiving.assetName}（已用 ${_formatDays(longestLiving.calculatedDays)}）'
                  : '-',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建总览行
  Widget _buildOverviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

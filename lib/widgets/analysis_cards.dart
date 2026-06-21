import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../services/asset_analysis_service.dart';
import '../utils/time_formatter.dart';

String formatAnalysisCurrency(double? amount) {
  if (amount == null) return '-';
  return '¥${amount.toStringAsFixed(2)}';
}

class AnalysisStatusDistributionCard extends StatelessWidget {
  final AssetStatusDistribution status;

  const AnalysisStatusDistributionCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
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
                  child: _StatusCard(
                    label: '服役中',
                    count: status.activeCount,
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(
                    label: '已退役',
                    count: status.retiredCount,
                    color: Colors.grey,
                    icon: Icons.pause_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(
                    label: '已卖出',
                    count: status.soldCount,
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
}

class _StatusCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class AnalysisCategoryPieCard extends StatelessWidget {
  static const _colors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.red,
    Colors.indigo,
    Colors.brown,
  ];

  final List<AssetCategoryBreakdown> categories;
  final double totalValue;

  const AnalysisCategoryPieCard({
    super.key,
    required this.categories,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
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
            if (totalValue == 0)
              const Center(child: Text('暂无价值数据'))
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final legend = _CategoryLegend(categories: categories);
                  final chart = SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: categories.asMap().entries.map((entry) {
                          final stat = entry.value;
                          return PieChartSectionData(
                            color: _colors[entry.key % _colors.length],
                            value: stat.value,
                            title:
                                '${(stat.value / totalValue * 100).toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );

                  if (constraints.maxWidth < 460) {
                    return Column(
                      children: [
                        chart,
                        const SizedBox(height: 16),
                        Align(alignment: Alignment.centerLeft, child: legend),
                        const SizedBox(height: 16),
                        _TotalValueText(totalValue: totalValue),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: chart),
                          const SizedBox(width: 16),
                          Flexible(child: legend),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _TotalValueText(totalValue: totalValue),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  final List<AssetCategoryBreakdown> categories;

  const _CategoryLegend({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...categories.asMap().entries.map((entry) {
          final stat = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LegendItem(
              label: stat.category,
              color: AnalysisCategoryPieCard
                  ._colors[entry.key % AnalysisCategoryPieCard._colors.length],
              count: stat.count,
              value: stat.value,
            ),
          );
        }),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  final double value;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.count,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$count 件 · ${formatAnalysisCurrency(value)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalValueText extends StatelessWidget {
  final double totalValue;

  const _TotalValueText({required this.totalValue});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '总资产: ${formatAnalysisCurrency(totalValue)}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AnalysisDailyCostTopCard extends StatelessWidget {
  final List<Asset> assets;

  const AnalysisDailyCostTopCard({super.key, required this.assets});

  @override
  Widget build(BuildContext context) {
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
            if (assets.isEmpty)
              const Center(child: Text('暂无数据'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assets.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final asset = assets[index];
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
                      formatAnalysisCurrency(asset.dailyCost),
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
}

class AnalysisOverviewCard extends StatelessWidget {
  final AssetOverview overview;
  final String timeDisplayMode;

  const AnalysisOverviewCard({
    super.key,
    required this.overview,
    required this.timeDisplayMode,
  });

  @override
  Widget build(BuildContext context) {
    final longestLiving = overview.longestLiving;

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
            _OverviewRow(
              label: '总资产',
              value: formatAnalysisCurrency(overview.totalAssets),
            ),
            _OverviewRow(
              label: '日均总消耗',
              value: formatAnalysisCurrency(overview.dailyCost),
            ),
            _OverviewRow(
              label: '平均每件',
              value: formatAnalysisCurrency(overview.averagePerItem),
            ),
            _OverviewRow(
              label: '最贵资产',
              value: overview.mostExpensive?.assetName ?? '-',
            ),
            _OverviewRow(
              label: '最长寿资产',
              value: longestLiving != null
                  ? '${longestLiving.assetName}（已用 ${TimeFormatter.formatDays(longestLiving.calculatedDays, mode: timeDisplayMode)}）'
                  : '-',
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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

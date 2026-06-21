import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/asset_provider.dart';
import '../services/asset_analysis_service.dart';
import '../widgets/analysis_cards.dart';

/// 分析页面 - 展示资产统计与分析
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String _timeDisplayMode = 'auto';

  @override
  void initState() {
    super.initState();
    _loadTimeDisplayMode();
  }

  Future<void> _loadTimeDisplayMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _timeDisplayMode = prefs.getString('time_display_mode') ?? 'auto';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分析'), centerTitle: true, elevation: 0),
      body: Consumer<AssetProvider>(
        builder: (context, provider, child) {
          final assets = provider.assets;

          if (assets.isEmpty) {
            return const _EmptyAnalysisState();
          }

          final analysis = AssetAnalysisService.calculate(assets);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnalysisStatusDistributionCard(status: analysis.status),
                    const SizedBox(height: 24),
                    AnalysisCategoryPieCard(
                      categories: analysis.categoryBreakdown,
                      totalValue: analysis.totalCategoryValue,
                    ),
                    const SizedBox(height: 24),
                    AnalysisDailyCostTopCard(
                      assets: analysis.dailyCostTopAssets,
                    ),
                    const SizedBox(height: 24),
                    AnalysisOverviewCard(
                      overview: analysis.overview,
                      timeDisplayMode: _timeDisplayMode,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyAnalysisState extends StatelessWidget {
  const _EmptyAnalysisState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            '暂无分析数据',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加资产后即可查看分析',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

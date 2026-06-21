import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/asset.dart';
import '../providers/asset_provider.dart';
import 'home_stats_card.dart';

class HomeAssetListContent extends StatelessWidget {
  final AssetProvider provider;
  final List<Asset> filteredAssets;
  final Map<String, dynamic> stats;
  final bool isMultiSelectMode;
  final int selectedCount;
  final String title;
  final Future<void> Function() onRefresh;
  final Widget Function(Asset asset) assetBuilder;

  const HomeAssetListContent({
    super.key,
    required this.provider,
    required this.filteredAssets,
    required this.stats,
    required this.isMultiSelectMode,
    required this.selectedCount,
    required this.title,
    required this.onRefresh,
    required this.assetBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
            ? _HomeErrorState(error: provider.error!, onRetry: onRefresh)
            : filteredAssets.isEmpty
            ? _HomeEmptyState(hasAnyAsset: provider.assets.isNotEmpty)
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: isMultiSelectMode ? 80 : 120,
                  left: 4,
                  right: 4,
                  top: 4,
                ),
                children: [
                  if (!isMultiSelectMode) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: HomeStatsCard(stats: stats),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isMultiSelectMode ? '已选 $selectedCount 项' : title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '共 ${filteredAssets.length} 项',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  MasonryGridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width >= 600
                        ? 3
                        : 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    itemCount: filteredAssets.length,
                    itemBuilder: (context, index) =>
                        assetBuilder(filteredAssets[index]),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _HomeErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
            const SizedBox(height: 10),
            Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  final bool hasAnyAsset;

  const _HomeEmptyState({required this.hasAnyAsset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              hasAnyAsset ? '当前分栏暂无资产' : '暂无资产数据',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              hasAnyAsset ? '切换其他分栏查看或添加新资产' : '点击右上角 + 添加您的第一个资产',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

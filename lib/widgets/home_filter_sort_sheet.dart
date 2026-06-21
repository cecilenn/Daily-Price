import 'package:flutter/material.dart';

import '../models/asset.dart';

class HomeFilterSortSheet extends StatefulWidget {
  final String sortBy;
  final bool sortAscending;
  final int? statusFilter;
  final Set<String> selectedCategories;
  final Set<String> selectedTags;
  final RangeValues? priceRange;
  final List<String> categories;
  final List<String> customTabs;
  final List<Asset> assets;
  final void Function(String sortBy, bool ascending) onSortChanged;
  final ValueChanged<int?> onStatusFilterChanged;
  final ValueChanged<Set<String>> onCategoryFiltersChanged;
  final ValueChanged<Set<String>> onTagFiltersChanged;
  final ValueChanged<RangeValues?> onPriceRangeChanged;
  final VoidCallback onReset;

  const HomeFilterSortSheet({
    super.key,
    required this.sortBy,
    required this.sortAscending,
    required this.statusFilter,
    required this.selectedCategories,
    required this.selectedTags,
    required this.priceRange,
    required this.categories,
    required this.customTabs,
    required this.assets,
    required this.onSortChanged,
    required this.onStatusFilterChanged,
    required this.onCategoryFiltersChanged,
    required this.onTagFiltersChanged,
    required this.onPriceRangeChanged,
    required this.onReset,
  });

  @override
  State<HomeFilterSortSheet> createState() => _HomeFilterSortSheetState();
}

class _HomeFilterSortSheetState extends State<HomeFilterSortSheet> {
  late String _sortBy;
  late bool _sortAscending;
  late int? _statusFilter;
  late Set<String> _selectedCategories;
  late Set<String> _selectedTags;
  late RangeValues? _priceRange;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant HomeFilterSortSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortBy != widget.sortBy ||
        oldWidget.sortAscending != widget.sortAscending ||
        oldWidget.statusFilter != widget.statusFilter ||
        oldWidget.priceRange != widget.priceRange ||
        oldWidget.selectedCategories != widget.selectedCategories ||
        oldWidget.selectedTags != widget.selectedTags) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    _sortBy = widget.sortBy;
    _sortAscending = widget.sortAscending;
    _statusFilter = widget.statusFilter;
    _selectedCategories = Set<String>.from(widget.selectedCategories);
    _selectedTags = Set<String>.from(widget.selectedTags);
    _priceRange = widget.priceRange;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _buildSortSection(),
                  const Divider(),
                  _buildStatusFilterSection(),
                  const Divider(),
                  if (widget.categories.isNotEmpty) ...[
                    _buildCategoryFilterSection(),
                    const Divider(),
                  ],
                  if (widget.customTabs.isNotEmpty) ...[
                    _buildTagFilterSection(),
                    const Divider(),
                  ],
                  _buildPriceFilterSection(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重置全部筛选'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('排序'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _sortChip('添加日期', 'created_at'),
            _sortChip('名称', 'name'),
            _sortChip('购入价格', 'price'),
            _sortChip('日均消费', 'dailyCost'),
            _sortChip('已用天数', 'daysUsed'),
            _sortChip('剩余天数', 'remainingDays'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ChoiceChip(
              label: const Text('升序'),
              selected: _sortAscending,
              onSelected: (selected) {
                if (selected) {
                  _changeSort(_sortBy, true);
                }
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('降序'),
              selected: !_sortAscending,
              onSelected: (selected) {
                if (selected) {
                  _changeSort(_sortBy, false);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  ChoiceChip _sortChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _sortBy == value,
      onSelected: (selected) {
        if (selected) {
          _changeSort(value, _sortAscending);
        }
      },
    );
  }

  Widget _buildStatusFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('状态筛选'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statusChip('全部', null),
            _statusChip('服役中', 0),
            _statusChip('已退役', 1),
            _statusChip('已卖出', 2),
          ],
        ),
      ],
    );
  }

  ChoiceChip _statusChip(String label, int? value) {
    return ChoiceChip(
      label: Text(label),
      selected: _statusFilter == value,
      onSelected: (selected) {
        if (selected) {
          setState(() => _statusFilter = value);
          widget.onStatusFilterChanged(value);
        }
      },
    );
  }

  Widget _buildCategoryFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('分类筛选'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.categories.map((category) {
            return FilterChip(
              label: Text(category),
              selected: _selectedCategories.contains(category),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
                widget.onCategoryFiltersChanged(Set.of(_selectedCategories));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('标签筛选'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.customTabs.map((tab) {
            final tag = 'custom_$tab';
            return FilterChip(
              label: Text(tab),
              selected: _selectedTags.contains(tag),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
                widget.onTagFiltersChanged(Set.of(_selectedTags));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceFilterSection() {
    final maxPrice = _calculateMaxPrice();
    final currentRange = _priceRange ?? RangeValues(0, maxPrice);
    final validStart = currentRange.start.clamp(0, maxPrice).toDouble();
    final validEnd = currentRange.end.clamp(0, maxPrice).toDouble();
    final validRange = RangeValues(
      validStart <= validEnd ? validStart : validEnd,
      validEnd >= validStart ? validEnd : validStart,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('价格区间'),
        const SizedBox(height: 12),
        Text(
          '¥${validRange.start.toStringAsFixed(0)} - ¥${validRange.end.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: validRange,
          min: 0,
          max: maxPrice,
          divisions: 20,
          labels: RangeLabels(
            '¥${validRange.start.toStringAsFixed(0)}',
            '¥${validRange.end.toStringAsFixed(0)}',
          ),
          onChanged: (values) {
            setState(() => _priceRange = values);
            widget.onPriceRangeChanged(values);
          },
        ),
      ],
    );
  }

  void _changeSort(String sortBy, bool ascending) {
    setState(() {
      _sortBy = sortBy;
      _sortAscending = ascending;
    });
    widget.onSortChanged(sortBy, ascending);
  }

  double _calculateMaxPrice() {
    var maxPrice = 10000.0;
    if (widget.assets.isNotEmpty) {
      final highestPrice = widget.assets
          .where((asset) => asset.purchasePrice != null)
          .fold(
            0.0,
            (max, asset) =>
                asset.purchasePrice! > max ? asset.purchasePrice! : max,
          );
      if (highestPrice > 0) {
        maxPrice = (highestPrice * 1.2).ceilToDouble();
      }
    }
    return maxPrice <= 0 ? 10000.0 : maxPrice;
  }

  void _resetFilters() {
    setState(() {
      _sortBy = 'created_at';
      _sortAscending = false;
      _statusFilter = null;
      _selectedCategories.clear();
      _selectedTags.clear();
      _priceRange = null;
    });
    widget.onReset();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

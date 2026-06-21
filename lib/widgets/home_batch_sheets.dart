import 'package:flutter/material.dart';

class HomeBatchTagSheet extends StatelessWidget {
  final List<String> customTabs;
  final ValueChanged<String> onTagSelected;

  const HomeBatchTagSheet({
    super.key,
    required this.customTabs,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Text(
              '选择要添加的标签',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (customTabs.isEmpty)
              const Text('暂无自定义标签')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: customTabs.map((tab) {
                  return FilterChip(
                    label: Text(tab),
                    selected: false,
                    onSelected: (selected) {
                      if (selected) {
                        onTagSelected('custom_$tab');
                      }
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class HomeBatchCategoryDialog extends StatelessWidget {
  final List<String> categories;
  final ValueChanged<String> onCategorySelected;

  const HomeBatchCategoryDialog({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择分类'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: categories
            .map(
              (category) => ListTile(
                title: Text(category),
                onTap: () => onCategorySelected(category),
              ),
            )
            .toList(),
      ),
    );
  }
}

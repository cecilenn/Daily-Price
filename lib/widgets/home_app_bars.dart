import 'package:flutter/material.dart';

class HomeNormalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<String> categories;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onCategoryMenuOpened;
  final VoidCallback onFilterPressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onScanPressed;

  const HomeNormalAppBar({
    super.key,
    required this.title,
    required this.categories,
    required this.onCategorySelected,
    required this.onCategoryMenuOpened,
    required this.onFilterPressed,
    required this.onSearchPressed,
    required this.onScanPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      centerTitle: true,
      elevation: 0,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.folder_outlined),
            tooltip: '分类',
            onSelected: onCategorySelected,
            onOpened: onCategoryMenuOpened,
            itemBuilder: (context) {
              return <PopupMenuEntry<String>>[
                const PopupMenuItem(value: 'all', child: Text('全部')),
                const PopupMenuDivider(),
                ...categories.map(
                  (category) =>
                      PopupMenuItem(value: category, child: Text(category)),
                ),
              ];
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '筛选与排序',
            onPressed: onFilterPressed,
          ),
        ],
      ),
      leadingWidth: 100,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '搜索',
          onPressed: onSearchPressed,
        ),
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: '扫码入库',
          onPressed: onScanPressed,
        ),
      ],
    );
  }
}

class HomeSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final String searchQuery;
  final VoidCallback onBackPressed;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearPressed;

  const HomeSearchAppBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onBackPressed,
    required this.onSearchChanged,
    required this.onClearPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed,
      ),
      title: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '搜索资产名称...',
          border: InputBorder.none,
        ),
        onChanged: onSearchChanged,
      ),
      centerTitle: false,
      elevation: 0,
      actions: [
        if (searchQuery.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: onClearPressed),
      ],
    );
  }
}

class HomeMultiSelectAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int selectedCount;
  final bool allSelected;
  final VoidCallback onClosePressed;
  final VoidCallback onToggleAllPressed;

  const HomeMultiSelectAppBar({
    super.key,
    required this.selectedCount,
    required this.allSelected,
    required this.onClosePressed,
    required this.onToggleAllPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onClosePressed,
      ),
      title: Text('已选 $selectedCount 项'),
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            allSelected ? Icons.check_box : Icons.check_box_outline_blank,
          ),
          onPressed: onToggleAllPressed,
        ),
      ],
    );
  }
}

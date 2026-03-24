import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'analysis_screen.dart';
import 'settings_screen.dart';
import 'add_edit_asset_screen.dart';

/// 主标签页屏幕 - V2.0 悬浮岛风格
class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;

  // 控制悬浮岛显示状态
  final ValueNotifier<bool> _hideDock = ValueNotifier<bool>(false);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(hideDockNotifier: _hideDock),
      const AnalysisScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _hideDock.dispose();
    super.dispose();
  }

  /// 跳转到添加资产页面
  Future<void> _navigateToAddAsset() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAssetScreen()),
    );
    // 如果添加成功，刷新当前页面
    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // 让内容滚到底部栏下方形成悬浮穿透效果
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildFloatingDock(),
    );
  }

  /// 构建悬浮岛底部导航栏 - V2.0 iOS 毛玻璃特效
  Widget _buildFloatingDock() {
    return ValueListenableBuilder<bool>(
      valueListenable: _hideDock,
      builder: (context, hideDock, child) {
        if (hideDock) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // 左侧胶囊导航栏 - 毛玻璃效果
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNavItem(
                              0,
                              Icons.folder_outlined,
                              Icons.folder,
                            ),
                            _buildNavItem(
                              1,
                              Icons.bar_chart_outlined,
                              Icons.bar_chart,
                            ),
                            _buildNavItem(
                              2,
                              Icons.settings_outlined,
                              Icons.settings,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 右侧悬浮添加按钮
                const SizedBox(width: 12),
                _buildAddButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建导航项
  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon) {
    final isSelected = _selectedIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? primaryColor : Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                _getNavItemLabel(index),
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? primaryColor : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取导航项标签
  String _getNavItemLabel(int index) {
    switch (index) {
      case 0:
        return '资产';
      case 1:
        return '分析';
      case 2:
        return '设置';
      default:
        return '';
    }
  }

  /// 构建添加按钮
  Widget _buildAddButton() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToAddAsset,
          borderRadius: BorderRadius.circular(28),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

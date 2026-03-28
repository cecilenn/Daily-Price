import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'theme_settings_screen.dart';
import 'category_settings_screen.dart';
import 'tag_settings_screen.dart';
import 'preference_settings_screen.dart';
import 'data_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              _buildSectionHeader('设置'),

              // 外观与主题
              Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  return ListTile(
                    leading: Icon(
                      appProvider.theme == AppTheme.light
                          ? Icons.light_mode
                          : appProvider.theme == AppTheme.dark
                          ? Icons.dark_mode
                          : Icons.eco,
                    ),
                    title: const Text('外观与主题'),
                    subtitle: Text(_getThemeName(appProvider.theme)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThemeSettingsScreen(),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),

              // 分类管理
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('分类管理'),
                subtitle: const Text('管理资产分类'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategorySettingsScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),

              // 标签管理
              ListTile(
                leading: const Icon(Icons.label_outline),
                title: const Text('标签管理'),
                subtitle: const Text('管理自定义标签'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TagSettingsScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),

              // 偏好设置
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('偏好设置'),
                subtitle: const Text('启动设置、显示格式'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PreferenceSettingsScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),

              // 数据管理
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('数据管理'),
                subtitle: const Text('导入导出数据'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataSettingsScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),

              const SizedBox(height: 24),

              // 关于
              _buildSectionHeader('关于'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本'),
                subtitle: const Text('1.5.1'),
              ),
              const Divider(height: 1),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return '极简留白';
      case AppTheme.dark:
        return '暗黑模式';
      case AppTheme.green:
        return '复古护眼';
      case AppTheme.morandi:
        return '莫兰迪灰紫';
      case AppTheme.warm:
        return '暖杏奶咖';
      case AppTheme.midnight:
        return '深邃靛蓝';
      case AppTheme.custom:
        return '自定义主题';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

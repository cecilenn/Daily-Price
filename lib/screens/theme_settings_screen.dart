import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('外观与主题'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return ListView(
                children: [
                  _buildSectionHeader('主题风格'),
                  _buildThemeGrid(appProvider),
                  const Divider(height: 1),
                  _buildSectionHeader('自定义'),
                  _buildCustomThemeOption(context, appProvider),
                  const Divider(height: 1),
                ],
              );
            },
          ),
        ),
      ),
    );
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

  Widget _buildThemeGrid(AppProvider appProvider) {
    final themes = [
      _ThemeInfo(
        AppTheme.light,
        '极简留白',
        Icons.light_mode,
        Colors.blue,
        '清爽明亮的浅色主题',
      ),
      _ThemeInfo(
        AppTheme.dark,
        '暗黑模式',
        Icons.dark_mode,
        Colors.blue,
        '护眼舒适的深色主题',
      ),
      _ThemeInfo(AppTheme.green, '复古护眼', Icons.eco, Colors.green, '温和的绿色护眼主题'),
      _ThemeInfo(
        AppTheme.morandi,
        '莫兰迪灰紫',
        Icons.palette,
        const Color(0xFF9B8B9B),
        '优雅的莫兰迪色调',
      ),
      _ThemeInfo(
        AppTheme.warm,
        '暖杏奶咖',
        Icons.wb_sunny,
        const Color(0xFFD4A574),
        '温暖舒适的杏咖色',
      ),
      _ThemeInfo(
        AppTheme.midnight,
        '深邃靛蓝',
        Icons.nightlight_round,
        const Color(0xFF3F51B5),
        '深沉的靛蓝夜空',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final themeInfo = themes[index];
          return _buildThemeCard(appProvider, themeInfo);
        },
      ),
    );
  }

  Widget _buildThemeCard(AppProvider appProvider, _ThemeInfo themeInfo) {
    final isSelected = appProvider.theme == themeInfo.theme;

    return GestureDetector(
      onTap: () => appProvider.setTheme(themeInfo.theme),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? themeInfo.color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? themeInfo.color.withValues(alpha: 0.1)
              : Colors.white,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(themeInfo.icon, color: themeInfo.color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          themeInfo.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? themeInfo.color
                                : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    themeInfo.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 预览色块
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: themeInfo.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: themeInfo.color.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: themeInfo.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 选中标记
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: themeInfo.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomThemeOption(
    BuildContext context,
    AppProvider appProvider,
  ) {
    return ListTile(
      leading: const Icon(Icons.color_lens),
      title: const Text('自定义主色'),
      subtitle: const Text('选择您喜欢的颜色作为主题色'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showColorPicker(context, appProvider),
    );
  }

  Future<void> _showColorPicker(
    BuildContext context,
    AppProvider appProvider,
  ) async {
    // 读取当前已保存的自定义颜色，如果没有则用默认蓝
    final prefs = await SharedPreferences.getInstance();
    final savedColorValue = prefs.getInt('custom_primary_color');
    Color pickerColor = savedColorValue != null
        ? Color(savedColorValue)
        : const Color(0xFF2196F3);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('选择主题颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 使用 AppProvider 的新方法统一处理
                await appProvider.setCustomColor(pickerColor);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeInfo {
  final AppTheme theme;
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  _ThemeInfo(this.theme, this.name, this.icon, this.color, this.description);
}

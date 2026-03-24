import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceSettingsScreen extends StatefulWidget {
  const PreferenceSettingsScreen({super.key});

  @override
  State<PreferenceSettingsScreen> createState() =>
      _PreferenceSettingsScreenState();
}

class _PreferenceSettingsScreenState extends State<PreferenceSettingsScreen> {
  // 默认启动分类设置
  String _defaultCategory = 'all';
  final String _prefKey = 'default_startup_category';

  // 时长显示格式设置
  String _timeDisplayMode = 'auto';
  final String _timeDisplayPrefKey = 'time_display_mode';

  // 自定义分类列表（用于下拉选项）
  List<String> _customCategories = ['未分类'];
  final String _customCategoriesPrefKey = 'custom_categories';

  // 时长显示模式选项
  final List<Map<String, String>> _timeModeOptions = [
    {'value': 'auto', 'label': '自动计算', 'desc': '1年3月15天（推荐）'},
    {'value': 'smart', 'label': '自动合并', 'desc': '1.3年'},
    {'value': 'year', 'label': '年', 'desc': '1.3年'},
    {'value': 'month', 'label': '月', 'desc': '15月'},
    {'value': 'day', 'label': '日', 'desc': '465天'},
  ];

  // 获取完整的分类选项（包含自定义分类）
  List<Map<String, String>> get _categoryOptions {
    final options = <Map<String, String>>[
      {'value': 'all', 'label': '全部'},
    ];
    for (final category in _customCategories) {
      options.add({'value': category, 'label': category});
    }
    return options;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 加载所有设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultCategory = prefs.getString(_prefKey) ?? 'all';
      _timeDisplayMode = prefs.getString(_timeDisplayPrefKey) ?? 'auto';
      _customCategories =
          prefs.getStringList(_customCategoriesPrefKey) ?? ['未分类'];
    });
  }

  /// 保存默认启动分栏设置
  Future<void> _saveDefaultCategory(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, value);
    setState(() {
      _defaultCategory = value;
    });
  }

  /// 保存时长显示模式设置
  Future<void> _saveTimeDisplayMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeDisplayPrefKey, value);
    setState(() {
      _timeDisplayMode = value;
    });
  }

  /// 获取时长显示模式的标签
  String _getTimeModeLabel(String mode) {
    final option = _timeModeOptions.firstWhere(
      (opt) => opt['value'] == mode,
      orElse: () => {'label': '未知'},
    );
    return option['label'] ?? '未知';
  }

  /// 显示时长显示模式选择对话框
  void _showTimeModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('时长显示格式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _timeModeOptions.map((option) {
            return RadioListTile<String>(
              title: Text(option['label']!),
              subtitle: Text(
                option['desc']!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              value: option['value']!,
              groupValue: _timeDisplayMode,
              onChanged: (value) {
                if (value != null) {
                  _saveTimeDisplayMode(value);
                  Navigator.pop(context);
                }
              },
              activeColor: Colors.green,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('偏好设置'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              _buildSectionHeader('启动设置'),

              // 默认启动分栏
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '默认启动分类',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      width: 160,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _defaultCategory,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          items: _categoryOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option['value'],
                              child: Text(
                                option['label']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _saveDefaultCategory(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              _buildSectionHeader('显示设置'),

              // 时长显示格式
              ListTile(
                title: const Text('时长显示格式'),
                subtitle: Text(_getTimeModeLabel(_timeDisplayMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showTimeModeDialog(),
              ),
              const Divider(height: 1),

              // 日期格式（预留）
              ListTile(
                title: const Text('日期格式'),
                subtitle: const Text('即将支持'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('日期格式设置即将支持'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
            ],
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
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式枚举
enum AppTheme {
  dark, // 默认暗黑
  light, // 极简留白
  green, // 复古护眼
  morandi, // 莫兰迪灰紫
  warm, // 暖杏奶咖
  midnight, // 深邃靛蓝
  custom, // 自定义主色
}

/// 日期显示格式枚举
enum DateFormatStyle {
  days, // 纯天数
  combined, // 年/月/日组合
}

/// 应用状态提供者
class AppProvider with ChangeNotifier {
  AppTheme _theme = AppTheme.light;
  DateFormatStyle _dateFormatStyle = DateFormatStyle.combined;
  DateTime? _lastSyncTime;
  final bool _isLoading = false;
  Color _customPrimaryColor = const Color(0xFF2196F3);

  AppTheme get theme => _theme;
  DateFormatStyle get dateFormatStyle => _dateFormatStyle;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isLoading => _isLoading;
  Color get customPrimaryColor => _customPrimaryColor;

  AppProvider() {
    loadSettings();
  }

  /// 加载本地设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 读取主题
    _theme = AppTheme.values.firstWhere(
      (e) => e.name == prefs.getString('theme'),
      orElse: () => AppTheme.dark,
    );

    // 读取日期格式
    _dateFormatStyle = DateFormatStyle.values.firstWhere(
      (e) => e.name == prefs.getString('dateFormatStyle'),
      orElse: () => DateFormatStyle.combined,
    );

    // 读取自定义颜色
    final savedColor = prefs.getInt('custom_primary_color');
    if (savedColor != null) {
      _customPrimaryColor = Color(savedColor);
    }

    notifyListeners();
  }

  /// 切换并保存主题
  Future<void> setTheme(AppTheme newTheme) async {
    _theme = newTheme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', newTheme.name);
  }

  /// 切换并保存日期显示格式
  Future<void> setDateFormatStyle(DateFormatStyle newStyle) async {
    _dateFormatStyle = newStyle;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dateFormatStyle', newStyle.name);
  }

  /// 获取时长显示模式
  Future<String> getTimeDisplayMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('time_display_mode') ?? 'auto';
  }

  /// 设置自定义颜色
  Future<void> setCustomColor(Color color) async {
    _customPrimaryColor = color;
    _theme = AppTheme.custom;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('custom_primary_color', color.value);
    await prefs.setString('theme', AppTheme.custom.name);
  }

  /// 更新云端同步时间
  void updateSyncTime(DateTime time) {
    _lastSyncTime = time;
    notifyListeners();
  }
}

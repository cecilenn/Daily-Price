import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WebdavConfig {
  final String serverUrl; // e.g. "https://dav.example.com"
  final String username;
  final String password;
  final String assetsPath; // e.g. "/inspection/assets.json"
  final String sessionsPath; // e.g. "/inspection/sessions/"

  WebdavConfig({
    required this.serverUrl,
    this.username = '',
    this.password = '',
    this.assetsPath = '/inspection/assets.json',
    this.sessionsPath = '/inspection/sessions/',
  });

  Map<String, dynamic> toJson() => {
    'serverUrl': serverUrl,
    'username': username,
    'password': password,
    'assetsPath': assetsPath,
    'sessionsPath': sessionsPath,
  };

  factory WebdavConfig.fromJson(Map<String, dynamic> json) => WebdavConfig(
    serverUrl: json['serverUrl'] as String? ?? '',
    username: json['username'] as String? ?? '',
    password: json['password'] as String? ?? '',
    assetsPath: json['assetsPath'] as String? ?? '/inspection/assets.json',
    sessionsPath: json['sessionsPath'] as String? ?? '/inspection/sessions/',
  );

  /// 完整的资产文件 URL
  String get assetsUrl => '${serverUrl._rstrip('/')}$assetsPath';

  /// 给定分享码，返回会话文件 URL
  String sessionUrl(String shareCode) =>
      '${serverUrl._rstrip('/')}${sessionsPath._rstrip('/')}/$shareCode.json';

  static const _prefsKey = 'inspection_webdav_config';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(toJson()));
  }

  static Future<WebdavConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefsKey);
    if (str == null) return null;
    return WebdavConfig.fromJson(jsonDecode(str) as Map<String, dynamic>);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

extension _StringRstrip on String {
  String _rstrip(String char) {
    if (endsWith(char)) return substring(0, length - char.length);
    return this;
  }
}

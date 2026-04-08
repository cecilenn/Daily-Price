import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/company_asset.dart';
import 'webdav_config.dart';

class WebdavService {
  final WebdavConfig config;

  WebdavService(this.config);

  Map<String, String> get _authHeaders {
    final headers = <String, String>{};
    if (config.username.isNotEmpty) {
      final credentials = base64Encode(
        utf8.encode('${config.username}:${config.password}'),
      );
      headers['Authorization'] = 'Basic $credentials';
    }
    return headers;
  }

  /// 测试 WebDAV 连接
  Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse(config.assetsUrl), headers: _authHeaders)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 下载总资产列表
  Future<List<CompanyAsset>> fetchAssetList() async {
    final response = await http.get(
      Uri.parse(config.assetsUrl),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('下载资产列表失败: HTTP ${response.statusCode}');
    }
    final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
    return jsonList
        .map((e) => CompanyAsset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 上传会话到 WebDAV
  Future<void> uploadSession(String shareCode, Map<String, dynamic> data) async {
    final url = config.sessionUrl(shareCode);
    final body = utf8.encode(jsonEncode(data));
    final response = await http.put(
      Uri.parse(url),
      headers: {
        ..._authHeaders,
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: body,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('上传会话失败: HTTP ${response.statusCode}');
    }
  }

  /// 从 WebDAV 下载会话
  Future<Map<String, dynamic>> downloadSession(String shareCode) async {
    final url = config.sessionUrl(shareCode);
    final response = await http.get(
      Uri.parse(url),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('下载会话失败: HTTP ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// 生成随机分享码
  static String generateShareCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}

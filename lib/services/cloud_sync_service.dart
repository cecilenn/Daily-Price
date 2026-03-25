import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asset.dart';

class CloudSyncService {
  static final CloudSyncService instance = CloudSyncService._();
  CloudSyncService._();

  final SupabaseClient _client = Supabase.instance.client;

  bool get isLoggedIn => _client.auth.currentUser != null;
  String? get userEmail => _client.auth.currentUser?.email;

  /// 上传本地数据到云端（全量覆盖）
  Future<int> syncUp(List<Asset> assets) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('未登录');

    final data = assets.map((a) {
      final map = a.toMap();
      map['user_id'] = userId;
      map['updated_at'] = DateTime.now().toIso8601String();
      return map;
    }).toList();

    await _client.from('assets').upsert(data);
    return assets.length;
  }

  /// 从云端下载数据到本地（全量覆盖本地）
  Future<List<Asset>> syncDown() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('未登录');

    final response = await _client
        .from('assets')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((m) => Asset.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// 获取云端最后一条记录的更新时间
  Future<DateTime?> getLastSyncTime() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('assets')
        .select('updated_at')
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return DateTime.tryParse(response['updated_at'] as String? ?? '');
  }
}

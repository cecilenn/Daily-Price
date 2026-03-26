import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asset.dart';

class CloudSyncService {
  static final CloudSyncService instance = CloudSyncService._();
  CloudSyncService._();

  final SupabaseClient _client = Supabase.instance.client;

  bool get isLoggedIn => _client.auth.currentUser != null;
  String? get userEmail => _client.auth.currentUser?.email;

  /// 上传本地数据到云端（智能合并，减少数据丢失风险）
  Future<(int inserted, int updated, int deleted)> syncUp(List<Asset> assets) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('未登录');

    final now = DateTime.now().toIso8601String();

    // 拉取云端当前所有资产 id
    final cloudResponse = await _client
        .from('assets')
        .select('id')
        .eq('user_id', userId);

    final cloudIds = (cloudResponse as List).map((m) => m['id'] as String).toSet();
    final localIds = assets.map((a) => a.id).toSet();

    int inserted = 0, updated = 0, deletedCount = 0;

    // 云端有、本地没有 → 删除
    final toDelete = cloudIds.difference(localIds);
    if (toDelete.isNotEmpty) {
      await _client.from('assets').delete().eq('user_id', userId).inFilter('id', toDelete.toList());
      deletedCount = toDelete.length;
    }

    // 本地有 → 插入或更新（upsert 自动处理）
    if (assets.isNotEmpty) {
      final data = assets.map((a) {
        final map = a.toMap();
        map['user_id'] = userId;
        map['updated_at'] = now;
        return map;
      }).toList();

      await _client.from('assets').upsert(data);

      // 统计：云端已有的是更新，没有的是新增
      inserted = localIds.difference(cloudIds).length;
      updated = localIds.intersection(cloudIds).length;
    }

    return (inserted, updated, deletedCount);
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

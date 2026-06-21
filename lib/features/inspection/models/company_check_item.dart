import 'dart:convert';

class CompanyCheckItem {
  final String id;
  final String sessionId;
  final String assetCode;
  final String assetSnapshot; // JSON string of the asset data
  final int? confirmedAt; // null=未确认

  CompanyCheckItem({
    required this.id,
    required this.sessionId,
    required this.assetCode,
    required this.assetSnapshot,
    this.confirmedAt,
  });

  bool get isConfirmed => confirmedAt != null;

  Map<String, dynamic> get snapshotData {
    try {
      final decoded = jsonDecode(assetSnapshot);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return {'assetCode': assetCode, 'assetName': '未知资产'};
  }

  String get assetName =>
      snapshotData['assetName']?.toString() ??
      snapshotData['asset_name']?.toString() ??
      '未知资产';

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'asset_code': assetCode,
    'asset_snapshot': assetSnapshot,
    'confirmed_at': confirmedAt,
  };

  factory CompanyCheckItem.fromMap(Map<String, dynamic> map) =>
      CompanyCheckItem(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        assetCode: map['asset_code'] as String,
        assetSnapshot: map['asset_snapshot'] as String,
        confirmedAt: map['confirmed_at'] as int?,
      );
}

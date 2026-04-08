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

  Map<String, dynamic> get snapshotData =>
      jsonDecode(assetSnapshot) as Map<String, dynamic>;

  String get assetName => snapshotData['assetName'] ?? '未知资产';

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'asset_code': assetCode,
    'asset_snapshot': assetSnapshot,
    'confirmed_at': confirmedAt,
  };

  factory CompanyCheckItem.fromMap(Map<String, dynamic> map) => CompanyCheckItem(
    id: map['id'] as String,
    sessionId: map['session_id'] as String,
    assetCode: map['asset_code'] as String,
    assetSnapshot: map['asset_snapshot'] as String,
    confirmedAt: map['confirmed_at'] as int?,
  );
}

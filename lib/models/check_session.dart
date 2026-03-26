import 'dart:convert';

class CheckSession {
  final String id;
  final String name;
  final int createdAt;
  final int status; // 0=进行中, 1=已完成

  CheckSession({
    required this.id,
    required this.name,
    required this.createdAt,
    this.status = 0,
  });

  factory CheckSession.create({required String name}) {
    return CheckSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt,
    'status': status,
  };

  factory CheckSession.fromMap(Map<String, dynamic> map) => CheckSession(
    id: map['id'],
    name: map['name'],
    createdAt: map['created_at'],
    status: map['status'] ?? 0,
  );
}

class CheckItem {
  final String id;
  final String sessionId;
  final String assetId;
  final String assetSnapshot; // JSON string of the asset at scan time
  final int? confirmedAt; // null=未确认

  CheckItem({
    required this.id,
    required this.sessionId,
    required this.assetId,
    required this.assetSnapshot,
    this.confirmedAt,
  });

  bool get isConfirmed => confirmedAt != null;

  Map<String, dynamic> get snapshotData =>
      jsonDecode(assetSnapshot) as Map<String, dynamic>;

  String get assetName =>
      snapshotData['assetName'] ?? snapshotData['asset_name'] ?? '未知资产';

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'asset_id': assetId,
    'asset_snapshot': assetSnapshot,
    'confirmed_at': confirmedAt,
  };

  factory CheckItem.fromMap(Map<String, dynamic> map) => CheckItem(
    id: map['id'],
    sessionId: map['session_id'],
    assetId: map['asset_id'],
    assetSnapshot: map['asset_snapshot'],
    confirmedAt: map['confirmed_at'],
  );
}

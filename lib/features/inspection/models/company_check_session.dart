class CompanyCheckSession {
  final String id;
  final String name;
  final int createdAt;
  final int status; // 0=进行中, 1=已完成

  CompanyCheckSession({
    required this.id,
    required this.name,
    required this.createdAt,
    this.status = 0,
  });

  factory CompanyCheckSession.create({required String name}) {
    return CompanyCheckSession(
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

  factory CompanyCheckSession.fromMap(Map<String, dynamic> map) =>
      CompanyCheckSession(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: map['created_at'] as int,
        status: map['status'] as int? ?? 0,
      );
}

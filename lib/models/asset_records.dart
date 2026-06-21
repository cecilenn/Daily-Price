/// 续费记录
class RenewalRecord {
  final String id;
  final int renewalDate;
  final double price;
  final int durationDays;

  const RenewalRecord({
    required this.id,
    required this.renewalDate,
    required this.price,
    required this.durationDays,
  });

  int get expireDate =>
      renewalDate + Duration(days: durationDays).inMilliseconds;

  Map<String, dynamic> toMap() => {
    'id': id,
    'renewal_date': renewalDate,
    'price': price,
    'duration_days': durationDays,
  };

  factory RenewalRecord.fromMap(Map<String, dynamic> map) => RenewalRecord(
    id: map['id'] as String,
    renewalDate: map['renewal_date'] as int,
    price: (map['price'] as num).toDouble(),
    durationDays: map['duration_days'] as int,
  );

  RenewalRecord copyWith({
    String? id,
    int? renewalDate,
    double? price,
    int? durationDays,
  }) => RenewalRecord(
    id: id ?? this.id,
    renewalDate: renewalDate ?? this.renewalDate,
    price: price ?? this.price,
    durationDays: durationDays ?? this.durationDays,
  );
}

/// 耗材定义记录
class ConsumableRecord {
  final String id;
  final String name;
  final double price;
  final int cycleDays;
  final int purchasedAt;
  final int updatedAt;

  const ConsumableRecord({
    required this.id,
    required this.name,
    required this.price,
    required this.cycleDays,
    required this.purchasedAt,
    required this.updatedAt,
  });

  double get dailyCost => (cycleDays > 0 && price > 0) ? price / cycleDays : 0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'cycle_days': cycleDays,
    'purchased_at': purchasedAt,
    'updated_at': updatedAt,
  };

  factory ConsumableRecord.fromMap(Map<String, dynamic> map) =>
      ConsumableRecord(
        id:
            map['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: map['name'] as String,
        price: (map['price'] as num).toDouble(),
        cycleDays: map['cycle_days'] as int? ?? map['cycleDays'] as int? ?? 0,
        purchasedAt:
            (map['purchased_at'] as int?) ??
            (map['purchasedAt'] as int?) ??
            DateTime.now().millisecondsSinceEpoch,
        updatedAt:
            (map['updated_at'] as int?) ??
            (map['updatedAt'] as int?) ??
            DateTime.now().millisecondsSinceEpoch,
      );

  ConsumableRecord copyWith({
    String? id,
    String? name,
    double? price,
    int? cycleDays,
    int? purchasedAt,
    int? updatedAt,
  }) => ConsumableRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    cycleDays: cycleDays ?? this.cycleDays,
    purchasedAt: purchasedAt ?? this.purchasedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// 耗材更换记录
class ReplacementRecord {
  final String id;
  final String consumableName;
  final int replacedAt;
  final double price;
  final String? note;

  const ReplacementRecord({
    required this.id,
    required this.consumableName,
    required this.replacedAt,
    required this.price,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'consumable_name': consumableName,
    'replaced_at': replacedAt,
    'price': price,
    'note': note ?? '',
  };

  factory ReplacementRecord.fromMap(Map<String, dynamic> map) =>
      ReplacementRecord(
        id:
            map['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        consumableName: map['consumable_name'] as String,
        replacedAt: map['replaced_at'] as int,
        price: (map['price'] as num).toDouble(),
        note: map['note'] as String?,
      );
}

class CompanyAsset {
  final String assetCode; // 资产编码
  final String assetName; // 资产名称
  final String spec; // 规格型号
  final String department; // 使用部门
  final String user; // 使用人
  final String location; // 存放位置

  CompanyAsset({
    required this.assetCode,
    required this.assetName,
    this.spec = '',
    this.department = '',
    this.user = '',
    this.location = '',
  });

  factory CompanyAsset.fromJson(Map<String, dynamic> json) {
    return CompanyAsset(
      assetCode: json['资产编码']?.toString() ?? '',
      assetName: json['资产名称']?.toString() ?? '',
      spec: json['规格型号']?.toString() ?? '',
      department: json['使用部门']?.toString() ?? '',
      user: json['使用人']?.toString() ?? '',
      location: json['存放位置']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'asset_code': assetCode,
    'asset_name': assetName,
    'spec': spec,
    'department': department,
    'user': user,
    'location': location,
  };

  factory CompanyAsset.fromMap(Map<String, dynamic> map) => CompanyAsset(
    assetCode: map['asset_code'] as String,
    assetName: map['asset_name'] as String? ?? '',
    spec: map['spec'] as String? ?? '',
    department: map['department'] as String? ?? '',
    user: map['user'] as String? ?? '',
    location: map['location'] as String? ?? '',
  );

  /// 用于生成 assetSnapshot JSON
  Map<String, dynamic> toSnapshotJson() => {
    'assetCode': assetCode,
    'assetName': assetName,
    'spec': spec,
    'department': department,
    'user': user,
    'location': location,
  };
}

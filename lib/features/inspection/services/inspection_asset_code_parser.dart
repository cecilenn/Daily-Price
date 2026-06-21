import 'dart:convert';

class InspectionAssetCodeParser {
  const InspectionAssetCodeParser._();

  static String? parse(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        return _firstNonEmpty(data, [
          '资产编码',
          'assetCode',
          'asset_code',
          'code',
          'id',
        ]);
      }
    } catch (_) {}

    return raw;
  }

  static String? _firstNonEmpty(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return null;
  }
}

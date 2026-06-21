class AssetCategory {
  static const uncategorized = '未分类';

  static const _legacyCategories = {'physical', 'virtual', 'subscription'};

  static bool isLegacy(String? category) {
    return category != null && _legacyCategories.contains(category);
  }

  static String normalize(String? category) {
    final value = category?.trim();
    if (value == null || value.isEmpty || isLegacy(value)) {
      return uncategorized;
    }
    return value;
  }

  static String normalizeOwnership({
    required String? ownershipType,
    required String? category,
  }) {
    if (ownershipType == 'subscription' || category == 'subscription') {
      return 'subscription';
    }
    return 'buyout';
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import '../models/asset_category.dart';

class HomePreferences {
  final String currentCategory;
  final String sortBy;
  final bool sortAscending;

  const HomePreferences({
    required this.currentCategory,
    required this.sortBy,
    required this.sortAscending,
  });
}

class AssetPreferencesService {
  static const homeCurrentCategoryKey = 'home_current_category';
  static const homeSortByKey = 'home_sort_by';
  static const homeSortAscendingKey = 'home_sort_ascending';
  static const customTabsKey = 'custom_tabs';
  static const customCategoriesKey = 'custom_categories';
  static const defaultStartupCategoryKey = 'default_startup_category';

  const AssetPreferencesService._();

  static Future<HomePreferences> loadHomePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCategory = prefs.getString(homeCurrentCategoryKey);
    final defaultStartupCategory = prefs.getString(defaultStartupCategoryKey);
    final rawCategory = savedCategory ?? defaultStartupCategory;
    final category = normalizeCategorySelection(rawCategory, fallback: 'all');
    if (savedCategory != null && savedCategory != category) {
      await prefs.setString(homeCurrentCategoryKey, category);
    } else if (savedCategory == null &&
        defaultStartupCategory != null &&
        defaultStartupCategory != category) {
      await prefs.setString(defaultStartupCategoryKey, category);
    }

    return HomePreferences(
      currentCategory: category,
      sortBy: prefs.getString(homeSortByKey) ?? 'created_at',
      sortAscending: prefs.getBool(homeSortAscendingKey) ?? false,
    );
  }

  static Future<void> saveHomeCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      homeCurrentCategoryKey,
      normalizeCategorySelection(category),
    );
  }

  static Future<void> saveHomeSortSettings(
    String sortBy,
    bool ascending,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(homeSortByKey, sortBy);
    await prefs.setBool(homeSortAscendingKey, ascending);
  }

  static Future<List<String>> loadCustomTabs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(customTabsKey) ?? [];
  }

  static Future<void> saveCustomTabs(List<String> tabs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(customTabsKey, tabs);
  }

  static Future<List<String>> loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(customCategoriesKey);
    final normalized = normalizeCategoryList(raw);
    if (!_sameStringList(raw, normalized)) {
      await prefs.setStringList(customCategoriesKey, normalized);
    }
    return normalized;
  }

  static Future<void> saveCustomCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      customCategoriesKey,
      normalizeCategoryList(categories),
    );
  }

  static Future<String> loadDefaultStartupCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final category = normalizeCategorySelection(
      prefs.getString(defaultStartupCategoryKey),
      fallback: 'all',
    );
    if (category != prefs.getString(defaultStartupCategoryKey)) {
      await prefs.setString(defaultStartupCategoryKey, category);
    }
    return category;
  }

  static Future<void> saveDefaultStartupCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      defaultStartupCategoryKey,
      normalizeCategorySelection(category),
    );
  }

  static String normalizeCategorySelection(
    String? category, {
    String fallback = AssetCategory.uncategorized,
  }) {
    final value = category?.trim();
    if (value == null || value.isEmpty) return fallback;
    if (value == 'all' || value == 'pinned' || value.startsWith('custom_')) {
      return value;
    }
    return AssetCategory.normalize(value);
  }

  static List<String> normalizeCategoryList(List<String>? categories) {
    final result = <String>[];
    for (final category in categories ?? const <String>[]) {
      final normalized = normalizeCategorySelection(category);
      if (!result.contains(normalized)) {
        result.add(normalized);
      }
    }

    if (!result.contains(AssetCategory.uncategorized)) {
      result.insert(0, AssetCategory.uncategorized);
    }

    return result;
  }

  static bool _sameStringList(List<String>? left, List<String> right) {
    if (left == null || left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}

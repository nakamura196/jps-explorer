import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jps_item.dart';
import 'image_cache_service.dart';

class FavoritesService {
  static const _key = 'jps_favorites';

  Future<List<JpsItem>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];

    final list = jsonDecode(jsonStr) as List;
    return list
        .map((e) => JpsItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFavorites(List<JpsItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  Future<void> addFavorite(JpsItem item) async {
    final items = await loadFavorites();
    if (items.any((e) => e.id == item.id)) return;
    items.insert(0, item);
    await saveFavorites(items);
  }

  Future<void> removeFavorite(String itemId) async {
    final items = await loadFavorites();
    items.removeWhere((e) => e.id == itemId);
    await saveFavorites(items);
  }

  Future<bool> isFavorite(String itemId) async {
    final items = await loadFavorites();
    return items.any((e) => e.id == itemId);
  }

  Future<void> cacheImagesForFavorites(ImageCacheService imageCache) async {
    final items = await loadFavorites();
    for (final item in items) {
      if (item.thumbnailUrl == null) continue;
      final cached = await imageCache.getCachedImage(item.thumbnailUrl!);
      if (cached != null) continue;
      try {
        await imageCache.cacheImage(item.thumbnailUrl!);
      } catch (_) {
        // Silently skip images that fail to download
      }
    }
  }
}

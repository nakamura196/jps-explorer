import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jps_item.dart';
import 'jps_api_service.dart';

class DailyPickService {
  static const _dateKey = 'daily_pick_date';
  static const _itemKey = 'daily_pick_item';

  final JpsApiService _api;

  DailyPickService(this._api);

  /// Returns today's pick. If already cached for today, returns cached.
  /// Otherwise fetches a random item and caches it.
  Future<JpsItem?> getTodaysPick() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cachedDate = prefs.getString(_dateKey);

    if (cachedDate == today) {
      final cachedJson = prefs.getString(_itemKey);
      if (cachedJson != null) {
        return JpsItem.fromJson(jsonDecode(cachedJson));
      }
    }

    // Fetch random item
    // Use a random offset into search results
    final random = Random(today.hashCode); // deterministic per day
    final offset = random.nextInt(1000);

    // Search with popular Japanese cultural terms
    final queries = [
      '浮世絵',
      '屏風',
      '古地図',
      '仏像',
      '刀剣',
      '茶碗',
      '掛軸',
      '着物',
      '能面',
      '土器',
    ];
    final query = queries[random.nextInt(queries.length)];

    try {
      final result =
          await _api.searchItems(keyword: query, size: 1, from: offset);
      if (result.items.isNotEmpty) {
        final item = result.items.first;
        await prefs.setString(_dateKey, today);
        await prefs.setString(_itemKey, jsonEncode(item.toJson()));
        return item;
      }
    } catch (_) {}
    return null;
  }
}

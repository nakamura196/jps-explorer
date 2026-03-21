import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jps_item.dart';
import '../services/jps_api_service.dart';
import '../services/favorites_service.dart';
import '../services/label_service.dart';
import '../services/nearby_notification_service.dart';
import '../services/daily_pick_service.dart';
import '../services/spotlight_service.dart';

// Services
final spotlightServiceProvider = Provider<SpotlightService>((ref) => SpotlightService());
final jpsApiProvider = Provider<JpsApiService>((ref) => JpsApiService());
final favoritesServiceProvider =
    Provider<FavoritesService>((ref) => FavoritesService());
final nearbyNotificationProvider =
    Provider<NearbyNotificationService>((ref) {
  final api = ref.watch(jpsApiProvider);
  return NearbyNotificationService(api: api);
});
final nearbyEnabledProvider = StateProvider<bool>((ref) => false);
final labelServiceProvider =
    Provider<LabelService>((ref) => LabelService());

// Daily pick
final dailyPickServiceProvider = Provider<DailyPickService>((ref) {
  return DailyPickService(ref.watch(jpsApiProvider));
});

final dailyPickProvider = FutureProvider<JpsItem?>((ref) async {
  final service = ref.watch(dailyPickServiceProvider);
  return service.getTodaysPick();
});

// Theme
enum AppTheme { system, light, dark }

final appThemeProvider = StateProvider<AppTheme>((ref) => AppTheme.system);

// Language
final appLanguageProvider = StateProvider<String?>((ref) => null);

// Explore tab state
final exploreQueryProvider = StateProvider<String>((ref) => '');
final exploreSearchTypeProvider =
    StateProvider<ExploreSearchType>((ref) => ExploreSearchType.motif);

enum ExploreSearchType { motif, keyword }

final exploreResultProvider =
    FutureProvider.autoDispose<JpsSearchResult?>((ref) async {
  final query = ref.watch(exploreQueryProvider);
  final searchType = ref.watch(exploreSearchTypeProvider);
  if (query.isEmpty) return null;

  final api = ref.watch(jpsApiProvider);
  if (searchType == ExploreSearchType.motif) {
    return api.searchByMotif(motif: query);
  } else {
    return api.searchItems(keyword: query);
  }
});

// Similar images
final similarItemIdProvider = StateProvider<String?>((ref) => null);

final similarResultProvider =
    FutureProvider.autoDispose<JpsSearchResult?>((ref) async {
  final itemId = ref.watch(similarItemIdProvider);
  if (itemId == null) return null;

  final api = ref.watch(jpsApiProvider);
  return api.searchSimilarImages(itemId: itemId);
});

// Map tab state
final mapSearchResultProvider =
    StateProvider<JpsSearchResult?>((ref) => null);

// Gallery tab state
final galleryListProvider =
    FutureProvider.autoDispose<List<JpsGallery>>((ref) async {
  final api = ref.watch(jpsApiProvider);
  return api.searchGalleries(size: 50);
});

// Favorites
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<JpsItem>>(
  (ref) => FavoritesNotifier(ref.watch(favoritesServiceProvider)),
);

class FavoritesNotifier extends StateNotifier<List<JpsItem>> {
  final FavoritesService _service;

  FavoritesNotifier(this._service) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _service.loadFavorites();
  }

  Future<void> toggle(JpsItem item) async {
    final isFav = state.any((e) => e.id == item.id);
    if (isFav) {
      await _service.removeFavorite(item.id);
    } else {
      await _service.addFavorite(item);
    }
    state = await _service.loadFavorites();
  }

  bool isFavorite(String itemId) => state.any((e) => e.id == itemId);
}

// Era search
final eraRangeProvider =
    StateProvider<(int, int)>((ref) => (1603, 1868)); // Edo default

final eraSearchResultProvider =
    FutureProvider.autoDispose<JpsSearchResult?>((ref) async {
  final range = ref.watch(eraRangeProvider);
  final api = ref.watch(jpsApiProvider);
  return api.searchByEra(startYear: range.$1, endYear: range.$2);
});

// Settings persistence
Future<void> loadSettings(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('theme') ?? 0;
  ref.read(appThemeProvider.notifier).state = AppTheme.values[themeIndex];
  ref.read(appLanguageProvider.notifier).state = prefs.getString('language');
}

Future<void> saveTheme(WidgetRef ref, AppTheme theme) async {
  ref.read(appThemeProvider.notifier).state = theme;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('theme', theme.index);
}

Future<void> saveLanguage(WidgetRef ref, String? language) async {
  ref.read(appLanguageProvider.notifier).state = language;
  final prefs = await SharedPreferences.getInstance();
  if (language != null) {
    await prefs.setString('language', language);
  } else {
    await prefs.remove('language');
  }
}

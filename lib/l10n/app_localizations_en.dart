// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JPS Explorer';

  @override
  String get tabExplore => 'Explore';

  @override
  String get tabMap => 'Map';

  @override
  String get tabGallery => 'Gallery';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get searchHint => 'Search motif (e.g. crane, Mt. Fuji)';

  @override
  String get searchKeyword => 'Search keyword';

  @override
  String get similarImages => 'Similar images';

  @override
  String get noResults => 'No results found';

  @override
  String get loading => 'Loading...';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get itemDetail => 'Item Detail';

  @override
  String get source => 'Source';

  @override
  String get database => 'Database';

  @override
  String get viewOriginal => 'View original';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get share => 'Share';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get about => 'About';

  @override
  String get nearbyItems => 'Nearby cultural resources';

  @override
  String get locationPermission => 'Location permission is required';

  @override
  String get eraSlider => 'Era';

  @override
  String get eraAncient => 'Ancient';

  @override
  String get eraMedieval => 'Medieval';

  @override
  String get eraEdo => 'Edo';

  @override
  String get eraMeiji => 'Meiji';

  @override
  String get eraTaisho => 'Taisho';

  @override
  String get eraShowa => 'Showa';

  @override
  String get eraHeisei => 'Heisei';

  @override
  String get eraReiwa => 'Reiwa';

  @override
  String get filterType => 'Type';

  @override
  String get filterRights => 'Rights';

  @override
  String itemCount(int count) {
    return '$count items';
  }

  @override
  String get galleryFeatured => 'Featured galleries';

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get favoritesHint => 'Tap the heart icon on items to save them here';

  @override
  String get cameraSearch => 'Camera Search';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get pickFromGallery => 'Pick from Gallery';

  @override
  String get recognizedText => 'Recognized Text';

  @override
  String get searchWithText => 'Search Japan Search';

  @override
  String get noTextRecognized => 'No text was recognized';

  @override
  String get processing => 'Processing...';

  @override
  String get nearbyNotification => 'Nearby Notification';

  @override
  String get notificationEnabled =>
      'Notify when nearby cultural resources are found';

  @override
  String get notificationDisabled => 'Off';

  @override
  String get todaysPick => 'Today\'s Pick';

  @override
  String get tipJar => 'Tip Jar';

  @override
  String get tipJarDescription =>
      'If you enjoy this app, consider leaving a tip to support development';

  @override
  String get tipSmall => 'Coffee';

  @override
  String get tipMedium => 'Cake';

  @override
  String get tipLarge => 'Celebration';

  @override
  String get tipThankYou => 'Thank you for your support!';
}

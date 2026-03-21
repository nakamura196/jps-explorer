import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'JPS Explorer'**
  String get appTitle;

  /// No description provided for @tabExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get tabExplore;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// No description provided for @tabGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get tabGallery;

  /// No description provided for @tabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search motif (e.g. crane, Mt. Fuji)'**
  String get searchHint;

  /// No description provided for @searchKeyword.
  ///
  /// In en, this message translates to:
  /// **'Search keyword'**
  String get searchKeyword;

  /// No description provided for @similarImages.
  ///
  /// In en, this message translates to:
  /// **'Similar images'**
  String get similarImages;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @itemDetail.
  ///
  /// In en, this message translates to:
  /// **'Item Detail'**
  String get itemDetail;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @viewOriginal.
  ///
  /// In en, this message translates to:
  /// **'View original'**
  String get viewOriginal;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @nearbyItems.
  ///
  /// In en, this message translates to:
  /// **'Nearby cultural resources'**
  String get nearbyItems;

  /// No description provided for @locationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get locationPermission;

  /// No description provided for @eraSlider.
  ///
  /// In en, this message translates to:
  /// **'Era'**
  String get eraSlider;

  /// No description provided for @eraAncient.
  ///
  /// In en, this message translates to:
  /// **'Ancient'**
  String get eraAncient;

  /// No description provided for @eraMedieval.
  ///
  /// In en, this message translates to:
  /// **'Medieval'**
  String get eraMedieval;

  /// No description provided for @eraEdo.
  ///
  /// In en, this message translates to:
  /// **'Edo'**
  String get eraEdo;

  /// No description provided for @eraMeiji.
  ///
  /// In en, this message translates to:
  /// **'Meiji'**
  String get eraMeiji;

  /// No description provided for @eraTaisho.
  ///
  /// In en, this message translates to:
  /// **'Taisho'**
  String get eraTaisho;

  /// No description provided for @eraShowa.
  ///
  /// In en, this message translates to:
  /// **'Showa'**
  String get eraShowa;

  /// No description provided for @eraHeisei.
  ///
  /// In en, this message translates to:
  /// **'Heisei'**
  String get eraHeisei;

  /// No description provided for @eraReiwa.
  ///
  /// In en, this message translates to:
  /// **'Reiwa'**
  String get eraReiwa;

  /// No description provided for @filterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get filterType;

  /// No description provided for @filterRights.
  ///
  /// In en, this message translates to:
  /// **'Rights'**
  String get filterRights;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemCount(int count);

  /// No description provided for @galleryFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured galleries'**
  String get galleryFeatured;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavorites;

  /// No description provided for @favoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on items to save them here'**
  String get favoritesHint;

  /// No description provided for @cameraSearch.
  ///
  /// In en, this message translates to:
  /// **'Camera Search'**
  String get cameraSearch;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from Gallery'**
  String get pickFromGallery;

  /// No description provided for @recognizedText.
  ///
  /// In en, this message translates to:
  /// **'Recognized Text'**
  String get recognizedText;

  /// No description provided for @searchWithText.
  ///
  /// In en, this message translates to:
  /// **'Search Japan Search'**
  String get searchWithText;

  /// No description provided for @noTextRecognized.
  ///
  /// In en, this message translates to:
  /// **'No text was recognized'**
  String get noTextRecognized;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @nearbyNotification.
  ///
  /// In en, this message translates to:
  /// **'Nearby Notification'**
  String get nearbyNotification;

  /// No description provided for @notificationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notify when nearby cultural resources are found'**
  String get notificationEnabled;

  /// No description provided for @notificationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notificationDisabled;

  /// No description provided for @todaysPick.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Pick'**
  String get todaysPick;

  /// No description provided for @tipJar.
  ///
  /// In en, this message translates to:
  /// **'Tip Jar'**
  String get tipJar;

  /// No description provided for @tipJarDescription.
  ///
  /// In en, this message translates to:
  /// **'If you enjoy this app, consider leaving a tip to support development'**
  String get tipJarDescription;

  /// No description provided for @tipSmall.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get tipSmall;

  /// No description provided for @tipMedium.
  ///
  /// In en, this message translates to:
  /// **'Cake'**
  String get tipMedium;

  /// No description provided for @tipLarge.
  ///
  /// In en, this message translates to:
  /// **'Celebration'**
  String get tipLarge;

  /// No description provided for @tipThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your support!'**
  String get tipThankYou;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

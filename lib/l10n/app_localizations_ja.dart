// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'JPS Explorer';

  @override
  String get tabExplore => '探索';

  @override
  String get tabMap => 'マップ';

  @override
  String get tabGallery => 'ギャラリー';

  @override
  String get tabFavorites => 'お気に入り';

  @override
  String get searchHint => 'モチーフで検索（例: 鶴、富士山）';

  @override
  String get searchKeyword => 'キーワード検索';

  @override
  String get similarImages => '類似画像';

  @override
  String get noResults => '結果が見つかりませんでした';

  @override
  String get loading => '読み込み中...';

  @override
  String get errorOccurred => 'エラーが発生しました';

  @override
  String get retry => '再試行';

  @override
  String get itemDetail => 'アイテム詳細';

  @override
  String get source => '提供元';

  @override
  String get database => 'データベース';

  @override
  String get viewOriginal => '元のサイトで見る';

  @override
  String get addFavorite => 'お気に入りに追加';

  @override
  String get removeFavorite => 'お気に入りから削除';

  @override
  String get share => '共有';

  @override
  String get settings => '設定';

  @override
  String get theme => 'テーマ';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get language => '言語';

  @override
  String get about => 'このアプリについて';

  @override
  String get nearbyItems => '周辺の文化資源';

  @override
  String get locationPermission => '位置情報の許可が必要です';

  @override
  String get eraSlider => '時代';

  @override
  String get eraAncient => '古代';

  @override
  String get eraMedieval => '中世';

  @override
  String get eraEdo => '江戸';

  @override
  String get eraMeiji => '明治';

  @override
  String get eraTaisho => '大正';

  @override
  String get eraShowa => '昭和';

  @override
  String get eraHeisei => '平成';

  @override
  String get eraReiwa => '令和';

  @override
  String get filterType => '種類';

  @override
  String get filterRights => '利用条件';

  @override
  String itemCount(int count) {
    return '$count 件';
  }

  @override
  String get galleryFeatured => '注目のギャラリー';

  @override
  String get noFavorites => 'お気に入りはまだありません';

  @override
  String get favoritesHint => 'アイテムのハートアイコンをタップして保存できます';

  @override
  String get cameraSearch => 'カメラ検索';

  @override
  String get takePhoto => '撮影';

  @override
  String get pickFromGallery => '写真を選択';

  @override
  String get recognizedText => '認識されたテキスト';

  @override
  String get searchWithText => 'ジャパンサーチで検索';

  @override
  String get noTextRecognized => 'テキストが認識されませんでした';

  @override
  String get processing => '処理中...';

  @override
  String get nearbyNotification => '周辺通知';

  @override
  String get notificationEnabled => '近くの文化資源を通知します';

  @override
  String get notificationDisabled => 'オフ';

  @override
  String get todaysPick => '本日の一品';

  @override
  String get tipJar => 'チップ';

  @override
  String get tipJarDescription => 'このアプリが気に入ったら、開発を支援していただけると嬉しいです';

  @override
  String get tipSmall => 'コーヒー';

  @override
  String get tipMedium => 'ケーキ';

  @override
  String get tipLarge => 'お祝い';

  @override
  String get tipThankYou => 'ご支援ありがとうございます！';
}

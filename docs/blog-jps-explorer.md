---
title: "ジャパンサーチAPIを使ったiOS/Android文化資源探索アプリの開発"
date: '2026-03-21T00:00:00+09:00'
draft: true
tags:
- digitalhumanities
- japansearch
- flutter
- ios
- appstoreconnect
- automation
categories:
- Tech
slug: jps-explorer-app
description: "ジャパンサーチのWeb APIを使い、モチーフ検索・撮影画像での類似検索・位置情報連動などモバイルならではの機能を備えた文化資源探索アプリを開発した記録"
emoji: "🔍"
---

ジャパンサーチ（https://jpsearch.go.jp）のWeb APIを使い、日本の文化資源を探索するiOS/Androidアプリ「JPS Explorer」を開発しました。本記事では、API調査からアプリ実装、App Storeリリースの自動化までの過程を記録します。

## ジャパンサーチのAPI

ジャパンサーチは国立国会図書館が運営する、3,200万件以上のデジタル文化資源のメタデータを横断検索できるサービスです。簡易Web APIが公開されており、以下のような検索が可能です。

| パラメータ | 機能 |
|-----------|------|
| `keyword` | キーワード検索 |
| `text2image` | テキストでモチーフを指定して画像検索 |
| `image` | 既存アイテムIDで類似画像検索 |
| `g-coordinates` | 緯度・経度・半径で場所検索 |
| `r-tempo` | 年代範囲で時代検索 |

## API調査で発見した点

### 座標フィールドのキー名

位置情報検索（`g-coordinates`）のレスポンスで座標データは `common.coordinates` に格納されています。経度のキーは `lon` です。`lng` や `longitude` ではありません。

```json
"coordinates": {
  "lat": 35.669,
  "lon": 139.764
}
```

### ギャラリーAPIの多言語フィールド

ギャラリー検索（`/api/curation/search`）のレスポンスでは、`title` と `summary` が文字列ではなくオブジェクトです。

```json
"title": {"ja": "耳鳥斎", "en": "Jichosai"},
"image": {"url": "https://...", "thumbnailUrl": "https://..."}
```

単純に `.toString()` すると `{ja: 耳鳥斎, en: Jichosai}` のような文字列がUIに表示されてしまいます。

### ギャラリー詳細のアイテム構造

ギャラリー詳細（`/api/curation/{id}`）のアイテムは `contents` ではなく `parts` 配列にネストされています。`type: "jps-curation-list-item"` を再帰的に探索してIDを収集する必要があります。一部のギャラリーでは `subPages` にもアイテムが含まれています。

### 画像アップロードによる類似検索（非公開API）

公式APIガイドには記載されていませんが、Web UIのネットワーク通信を調査したところ、画像アップロードによる類似検索が3段階のAPIで実現されていることがわかりました。

1. `POST /dl/api/imagefeatures/` — 画像Base64 → 64次元特徴量ベクトル
2. `POST /api/item/create-image-feature` — 特徴量 → 一時的な検索ID
3. `GET /api/item/search/jps-cross?image={ID}` — 通常の類似検索

Step 2では `X-Requested-With: XmlHttpRequest` ヘッダーが必要です。レスポンスはプレーンテキストでIDが返ります。

この仕組みにより、カメラで撮影した画像から直接ジャパンサーチの類似画像検索が可能になりました。詳細は別記事にまとめています。

### 利用条件・データベース名のID問題

検索結果の `common.contentsRightsType` は `pdm`、`ccby` などのコード値です。`common.database` や `common.provider` もIDです。人間が読めるラベルを表示するには、別途 `/api/database/{id}` や `/api/organization/{id}` を呼び出してキャッシュする必要があります。

## アプリの実装

### 技術スタック

- Flutter + Riverpod（状態管理）
- flutter_map + OpenStreetMap（地図表示）
- Playwright + Cookie（DH Current Awarenessプロジェクトで使用、本アプリでは不使用）
- CachedNetworkImage（画像キャッシュ）
- 日英ローカライゼーション

### モバイルならではの機能

ブラウザ版ジャパンサーチとの差別化として、以下のモバイル固有の機能を実装しました。

| 機能 | 使用API | モバイル技術 |
|------|---------|------------|
| 撮影画像で類似検索 | 非公開API（imagefeatures） | カメラ / image_picker |
| 周辺文化資源の通知 | `g-coordinates` | バックグラウンド位置監視 + ローカル通知 |
| マップ探索 | `g-coordinates` | flutter_map + Geolocator |
| オフラインお気に入り | — | ローカルストレージ + 画像キャッシュ |
| Spotlight 連携 | — | CoreSpotlight（iOS MethodChannel） |
| 触覚フィードバック | — | HapticFeedback |
| 本日の一品 | `keyword`（ランダムオフセット） | SharedPreferences で日替わりキャッシュ |

### 周辺通知の実装

バックグラウンドで位置情報を監視し、500m以上移動したらJPS APIで周辺を検索、新しい文化資源が見つかったらローカル通知を送信します。バッテリー消費を抑えるため `LocationAccuracy.low` と `distanceFilter: 500` を使用しています。同じアイテムの重複通知は直近100件のIDを `SharedPreferences` に保持して防止しています。

### Spotlight連携

iOS の CoreSpotlight にアイテムをインデックスするため、`MethodChannel` で Swift のネイティブコードを呼び出しています。AppDelegate に直接実装する方法を採用しました。別ファイル（`SpotlightPlugin.swift`）にすると Xcode プロジェクトファイル（`.pbxproj`）への登録が必要で、CLIからの自動化が困難なためです。

## App Store リリースの自動化

### 自動化できた作業

`scripts/release.py` で以下をコマンドラインから実行できます。

```bash
python3 scripts/release.py build      # ビルド & アップロード
python3 scripts/release.py screenshots # スクリーンショット撮影
python3 scripts/release.py submit      # メタデータ設定 → 審査提出
```

| 作業 | 方法 |
|------|------|
| Bundle ID 登録 | `POST /v1/bundleIds` |
| ビルド & アップロード | `flutter build ipa` → `xcrun altool --upload-app` |
| メタデータ設定 | `PATCH /v1/appStoreVersionLocalizations/{id}` |
| スクリーンショット撮影 | `xcrun simctl io screenshot` + Pillow でマーケティング画像生成 |
| スクリーンショットアップロード | 3段階（予約→バイナリ→コミット） |
| 年齢レーティング | `PATCH /v1/ageRatingDeclarations/{id}` |
| カテゴリ・著作権 | `PATCH /v1/appInfos/{id}`, `PATCH /v1/appStoreVersions/{id}` |
| ビルド紐付け | `PATCH /v1/appStoreVersions/{id}/relationships/build` |
| 暗号化コンプライアンス | `PATCH /v1/builds/{id}` |
| レビュー詳細 | `POST /v1/appStoreReviewDetails` |
| 審査提出 | `POST /v1/reviewSubmissions` + `reviewSubmissionItems` |

### 自動化できなかった作業

| 作業 | 理由 |
|------|------|
| アプリの新規作成 | OpenAPI仕様で `/v1/apps` は GET のみ。POST は存在しない。APIエラーメッセージでも「CREATE is not allowed. Allowed operations are: GET_COLLECTION, GET_INSTANCE, UPDATE」と明示されている |
| App Privacy（データ使用状況の宣言） | OpenAPI仕様を網羅的に検索し、`appDataUsages`, `appDataUsageCategories`, `privacy` 関連のエンドポイントが v1/v2 いずれにも存在しないことを確認。唯一の手動必須項目。設定URL: `https://appstoreconnect.apple.com/apps/{APP_ID}/distribution/privacy` |
| In-App Purchase 商品の登録 | 初回のみブラウザから作成が必要 |

App Privacy については、既存のブログ記事「App Store Connect APIだけでiOSアプリを審査提出する手順」でも「APIが提供されていない」と記載しましたが、今回 OpenAPI 仕様の網羅的な検索で改めて確認できました。Apple が配布している公式 OpenAPI JSON（openapi.oas.json）の全パスを `privacy`, `dataUsage`, `consent`, `declaration` 等のキーワードで検索し、該当するエンドポイントが存在しないことを確認しています。

### .env による設定管理

APIキーや連絡先情報をハードコードせず、`.env` ファイルから読み込む設計にしています。

```text
# .env.example
APP_STORE_API_KEY=YOUR_KEY_ID
APP_STORE_API_ISSUER=YOUR_ISSUER_ID
BUNDLE_ID=com.example.myapp
CONTACT_FIRST_NAME=Taro
CONTACT_LAST_NAME=Yamada
CONTACT_EMAIL=taro@example.com
CONTACT_PHONE=+81-90-1234-5678
SUPPORT_URL=https://example.com
PRIVACY_URL=https://example.com/privacy
COPYRIGHT=2026 Your Name
```

### リリース作業で発見した注意点

#### 漏れやすい設定項目

APIで全項目を設定したつもりでも、以下が漏れやすいです。提出前にチェックスクリプトで確認することを推奨します。

| 項目 | API | 備考 |
|------|-----|------|
| Promotional Text | `appStoreVersionLocalizations` の `promotionalText` | 任意だが設定推奨。審査なしでいつでも変更可能 |
| Marketing URL | `appStoreVersionLocalizations` の `marketingUrl` | 任意 |
| Privacy URL（英語） | `appInfoLocalizations` | 日本語版と同じURLを設定しがち。英語版パスに修正が必要 |
| 価格設定 | `appPriceSchedules` | 無料アプリでも明示的に設定が必要。`appPricePoints` でFREE（price=0）のIDを取得して使う |

#### 初回バージョンでは whatsNew が設定不可

初回リリース時に `whatsNew`（新機能の説明）を設定すると 409 STATE_ERROR になります。このフィールドは2回目以降のバージョンアップ時のみ設定可能です。

#### 電話番号のフォーマット

レビュー詳細の `contactPhone` は `+国番号-番号` 形式が必要です。ダミーの番号（`+81-90-0000-0000`）は無効と判定されます。KotenOCR など既存アプリのレビュー詳細から `GET /v1/appStoreVersions/{id}/appStoreReviewDetail` で取得して流用するのが確実です。

### スクリーンショット撮影とマーケティング画像生成

Flutter の `integration_test` を使い、各画面のスクリーンショットを自動撮影しています。テスト内で `ActionChip` のタップや `NavigationBar` のアイコンタップを行い、探索→検索結果→詳細→マップ→ギャラリーの5画面を自動遷移します。

```dart
final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
// ... app.main() → pumpAndSettle → takeScreenshot
```

シミュレータの言語を切り替えて日本語・英語それぞれで撮影し、iPhone と iPad の2デバイスで実行することで、5画面 × 2言語 × 2デバイス = 20枚のスクリーンショットを自動で取得します。

マーケティング画像の生成は、参考プロジェクト（KotenOCR）の `generate_marketing_screenshots.py` をベースにしています。主なポイントは以下です。

- `SCREENSHOT_PRIORITY` でどの画面のスクリーンショットをどのテーマに割り当てるかを制御。ファイル名のプレフィックス（`02_search`, `05_gallery` 等）でマッチングする
- `find_best_screenshots(input_dir, count=5)` の `count` をテーマ数と一致させる必要がある。デフォルトの `count=3` だとテーマと画面の対応がずれる
- `bleed_fraction = 0.35` でデバイスの下部35%を画面外にはみ出させる「見切れレイアウト」にしている
- iPhone（アスペクト比 ~0.46）と iPad（~0.75）でフォントサイズやスクリーンショットの拡大率を自動調整
- `--input-iphone` と `--input-ipad` を別々に指定することで、それぞれの解像度に最適化された画像を使用
- 出力ファイル名は `marketing_01_iphone.png`, `marketing_01_ipad.png` のようにデバイス種別を含む形式

#### 審査提出後のスクリーンショット変更不可

審査に提出した後（Waiting For Review 状態）は、スクリーンショットの削除・追加ができません。「Can't Delete/Create Screenshot After Submit for review」エラーになります。スクリーンショットの品質は提出前に十分確認する必要があります。

#### スクリーンショットの言語問題

Flutter アプリのスクリーンショットを自動撮影する際、シミュレータの言語設定がアプリのUI言語に直結します。日本語のスクリーンショットを撮るにはシミュレータの言語を日本語に切り替える必要があります。また、同じスクリーンショットを複数枚コピーして使い回すと、審査でリジェクトされる可能性があります。ファイルのハッシュ値を比較して重複を検出するチェック機構を入れるのが望ましいです。

## 全体の構成

```text
jps_explorer/
├── lib/
│   ├── models/jps_item.dart
│   ├── services/
│   │   ├── jps_api_service.dart      # JPS API クライアント
│   │   ├── label_service.dart        # DB/org/rights ラベル解決
│   │   ├── daily_pick_service.dart   # 日替わりアイテム
│   │   ├── nearby_notification_service.dart
│   │   ├── image_cache_service.dart  # オフライン画像
│   │   ├── spotlight_service.dart    # iOS Spotlight
│   │   ├── favorites_service.dart
│   │   └── tip_jar_service.dart      # 投げ銭
│   ├── views/                        # 各画面
│   └── providers/app_providers.dart  # Riverpod
├── scripts/
│   ├── release.py                    # ビルド・提出の自動化
│   ├── capture_screenshots.sh        # スクリーンショット撮影
│   └── generate_marketing_screenshots.py  # マーケティング画像生成
├── .env                              # 設定（gitignore）
└── .env.example                      # 設定テンプレート
```

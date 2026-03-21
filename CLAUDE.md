# CLAUDE.md

## Project Overview

JPS Explorer — Japan Search (ジャパンサーチ) の文化資源を探索するiOS/Androidアプリ。Flutter + Riverpod。

## Build & Run

```bash
flutter pub get
flutter run -d <device_id>           # debug
flutter build ios --no-codesign      # iOS release build
flutter build apk                    # Android release build
flutter gen-l10n                     # regenerate l10n
dart run flutter_launcher_icons      # regenerate app icons
```

iOS minimum: 16.0 (Podfile)

## Architecture

- State management: Riverpod 2.x
- Localization: ARB files in lib/l10n/ (en, ja)
- API: Japan Search Web API (https://jpsearch.go.jp/api/)
- Map: flutter_map + OpenStreetMap tiles

## Key Files

```text
lib/
├── main.dart, app.dart
├── models/jps_item.dart              # JpsItem, JpsGallery, FacetEntry
├── providers/app_providers.dart      # All Riverpod providers
├── services/
│   ├── jps_api_service.dart          # Japan Search API client
│   ├── favorites_service.dart        # Local favorites persistence
│   ├── label_service.dart            # DB/org/rights label resolution
│   ├── daily_pick_service.dart       # Daily random item
│   ├── nearby_notification_service.dart  # Background location notifications
│   ├── image_cache_service.dart      # Offline image cache
│   └── spotlight_service.dart        # iOS Spotlight indexing
└── views/
    ├── home_view.dart                # Bottom nav (4 tabs)
    ├── explore_view.dart             # Motif/keyword search + sample chips
    ├── map_view.dart                 # Map + DraggableScrollableSheet
    ├── gallery_view.dart             # Curation galleries
    ├── favorites_view.dart           # Saved items (offline capable)
    ├── item_detail_view.dart         # Item detail + similar images
    ├── camera_search_view.dart       # Photo → image similarity search
    ├── daily_pick_card.dart          # Today's Pick card widget
    └── settings_view.dart            # Theme, language, notifications
```

## Japan Search API Endpoints

- `GET /api/item/search/jps-cross` — Item search (keyword, text2image, image, g-coordinates, r-tempo)
- `GET /api/item/{id}` — Item detail
- `GET /api/curation/search` — Gallery search
- `GET /api/curation/{id}` — Gallery detail
- `GET /api/database/{id}` — Database label
- `GET /api/organization/{id}` — Organization label
- `POST /dl/api/imagefeatures/` — Image → 64-dim feature vector (undocumented)
- `POST /api/item/create-image-feature` — Feature vector → temporary search ID (undocumented)

## API Notes

- Coordinates field uses `lon` (not `lng`): `common.coordinates.lat` / `common.coordinates.lon`
- Curation title/summary are objects `{ja: "...", en: "..."}`, not strings
- Curation image is object `{url: "...", thumbnailUrl: "..."}`
- Curation items are in `parts` array (recursive), type `jps-curation-list-item`
- Rights values are codes (pdm, ccby, etc.) — use LabelService for display

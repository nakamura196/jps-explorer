#!/bin/bash
set -euo pipefail

# JPS Explorer — 全スクリーンショット撮影スクリプト
# iPhone/iPad × 日本語/英語 × 各画面を撮影してマーケティング画像を生成する
#
# Usage:
#   ./scripts/take_all_screenshots.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SS_DIR="$PROJECT_DIR/screenshots"

IPHONE_SIM="iPhone 17 Pro Max"
IPAD_SIM="iPad Pro 13-inch (M5)"

IPHONE_UDID=$(xcrun simctl list devices available | grep "$IPHONE_SIM" | head -1 | grep -oE '[A-F0-9-]{36}')
IPAD_UDID=$(xcrun simctl list devices available | grep "$IPAD_SIM" | head -1 | grep -oE '[A-F0-9-]{36}')

echo "=== JPS Explorer Screenshot Pipeline ==="
echo "iPhone: $IPHONE_SIM ($IPHONE_UDID)"
echo "iPad:   $IPAD_SIM ($IPAD_UDID)"
echo ""

# Clean previous screenshots
rm -rf "$SS_DIR"
mkdir -p "$SS_DIR"

capture_device() {
    local UDID="$1"
    local DEVICE_TYPE="$2"  # iphone or ipad
    local LANG="$3"         # ja or en
    local OUTPUT_DIR="$SS_DIR/raw/${LANG}/${DEVICE_TYPE}"

    mkdir -p "$OUTPUT_DIR"

    echo ""
    echo "--- $DEVICE_TYPE / $LANG ---"

    # Boot simulator if not booted
    xcrun simctl boot "$UDID" 2>/dev/null || true
    sleep 3

    # Set simulator language
    xcrun simctl shutdown "$UDID" 2>/dev/null || true
    sleep 2
    if [ "$LANG" = "ja" ]; then
        defaults write com.apple.iphonesimulator "SimulatorLanguages_$UDID" -array "ja"
        defaults write com.apple.iphonesimulator "SimulatorLocale_$UDID" "ja_JP"
    else
        defaults write com.apple.iphonesimulator "SimulatorLanguages_$UDID" -array "en"
        defaults write com.apple.iphonesimulator "SimulatorLocale_$UDID" "en_US"
    fi
    xcrun simctl boot "$UDID" 2>/dev/null || true
    sleep 5

    # Install and launch app
    echo "  Installing app..."
    flutter build ios --simulator --no-codesign 2>/dev/null
    xcrun simctl install "$UDID" "$PROJECT_DIR/build/ios/iphonesimulator/Runner.app" 2>/dev/null || true
    xcrun simctl launch "$UDID" com.nakamura196.jpsExplorer 2>/dev/null || true
    sleep 8

    # Screen 1: Explore tab (home with daily pick + sample chips)
    echo "  [1/5] Explore..."
    sleep 3
    xcrun simctl io "$UDID" screenshot "$OUTPUT_DIR/01_explore.png"

    # Screen 2: Search results (tap a sample chip - simulate tap)
    echo "  [2/5] Search results..."
    # Tap on "鶴" or "crane" chip area (approximate coordinates)
    if [ "$DEVICE_TYPE" = "iphone" ]; then
        # iPhone 17 Pro Max: width=440, sample chips area around y=700
        xcrun simctl io "$UDID" sendkey "$UDID" 2>/dev/null || true
    fi
    # Wait for search to load
    sleep 5
    xcrun simctl io "$UDID" screenshot "$OUTPUT_DIR/02_search.png"

    # Screen 3: Map tab
    echo "  [3/5] Map..."
    # Navigate to Map tab - need to relaunch with deep link or use accessibility
    sleep 2
    xcrun simctl io "$UDID" screenshot "$OUTPUT_DIR/03_map.png"

    # Screen 4: Gallery tab
    echo "  [4/5] Gallery..."
    sleep 2
    xcrun simctl io "$UDID" screenshot "$OUTPUT_DIR/04_gallery.png"

    # Screen 5: Camera search
    echo "  [5/5] Camera search..."
    sleep 2
    xcrun simctl io "$UDID" screenshot "$OUTPUT_DIR/05_camera.png"

    echo "  Done: $(ls "$OUTPUT_DIR"/*.png | wc -l) screenshots"
}

# Interactive mode - ask user to navigate
capture_interactive() {
    local UDID="$1"
    local DEVICE_TYPE="$2"
    local LANG="$3"
    local OUTPUT_DIR="$SS_DIR/raw/${LANG}/${DEVICE_TYPE}"

    mkdir -p "$OUTPUT_DIR"

    echo ""
    echo "=== $DEVICE_TYPE / $LANG ==="
    echo "シミュレータで以下の画面を表示してください。"
    echo ""

    local screens=(
        "01_explore:探索タブ（本日の一品 + サンプルチップ表示）"
        "02_search:探索タブ（検索結果表示中、グリッドに画像が表示された状態）"
        "03_detail:アイテム詳細画面（サムネイル + メタデータ）"
        "04_map:マップタブ（検索ボタン押下後、結果リスト表示中）"
        "05_gallery:ギャラリータブ（一覧表示）"
    )

    for screen in "${screens[@]}"; do
        IFS=':' read -r name desc <<< "$screen"
        echo -n "  $desc を表示して Enter: "
        read
        xcrun simctl io "$UDID" screenshot "$OUTPUT_DIR/${name}.png"
        echo "    → ${name}.png"
    done

    echo "  Done: $(ls "$OUTPUT_DIR"/*.png 2>/dev/null | wc -l) screenshots"
}

# Resize screenshots to App Store required sizes
resize_all() {
    echo ""
    echo "=== Resizing ==="

    for LANG in ja en; do
        # iPhone 6.7": 1290x2796
        local IPHONE_IN="$SS_DIR/raw/$LANG/iphone"
        local IPHONE_OUT="$SS_DIR/resized/$LANG/iphone"
        if [ -d "$IPHONE_IN" ]; then
            mkdir -p "$IPHONE_OUT"
            for f in "$IPHONE_IN"/*.png; do
                [ -f "$f" ] || continue
                sips -z 2796 1290 "$f" --out "$IPHONE_OUT/$(basename "$f")" 2>/dev/null
            done
            echo "  $LANG/iphone: $(ls "$IPHONE_OUT"/*.png 2>/dev/null | wc -l) resized"
        fi

        # iPad 12.9": 2048x2732
        local IPAD_IN="$SS_DIR/raw/$LANG/ipad"
        local IPAD_OUT="$SS_DIR/resized/$LANG/ipad"
        if [ -d "$IPAD_IN" ]; then
            mkdir -p "$IPAD_OUT"
            for f in "$IPAD_IN"/*.png; do
                [ -f "$f" ] || continue
                sips -z 2732 2048 "$f" --out "$IPAD_OUT/$(basename "$f")" 2>/dev/null
            done
            echo "  $LANG/ipad: $(ls "$IPAD_OUT"/*.png 2>/dev/null | wc -l) resized"
        fi
    done
}

# Generate marketing images
generate_marketing() {
    echo ""
    echo "=== Marketing Images ==="

    for LANG in ja en; do
        for DEVICE in iphone ipad; do
            local INPUT="$SS_DIR/resized/$LANG/$DEVICE"
            local OUTPUT="$SS_DIR/marketing/$LANG/$DEVICE"
            if [ -d "$INPUT" ] && [ "$(ls "$INPUT"/*.png 2>/dev/null | wc -l)" -gt 0 ]; then
                python3 "$SCRIPT_DIR/generate_marketing_screenshots.py" \
                    --input-dir "$INPUT" \
                    --output-dir "$OUTPUT" \
                    --lang "$LANG" 2>&1 | tail -3
            fi
        done
    done
}

echo ""
echo "スクリーンショット撮影方法:"
echo "  1) 対話式（手動で画面を切り替えて撮影）"
echo ""

# iPhone Japanese
echo "=== Step 1/4: iPhone 日本語 ==="
echo "まずシミュレータの言語を日本語に設定してください。"
echo "設定アプリ → 一般 → 言語と地域 → 日本語"
echo "またはアプリ内設定で言語を日本語に切替えてください。"
capture_interactive "$IPHONE_UDID" "iphone" "ja"

# iPhone English
echo ""
echo "=== Step 2/4: iPhone English ==="
echo "アプリ内設定で言語を English に切替えてください。"
capture_interactive "$IPHONE_UDID" "iphone" "en"

# iPad Japanese
echo ""
echo "=== Step 3/4: iPad 日本語 ==="
echo "iPadシミュレータでアプリを起動してください。"
echo "  xcrun simctl boot $IPAD_UDID"
echo "  xcrun simctl install $IPAD_UDID build/ios/iphonesimulator/Runner.app"
echo "  xcrun simctl launch $IPAD_UDID com.nakamura196.jpsExplorer"
capture_interactive "$IPAD_UDID" "ipad" "ja"

# iPad English
echo ""
echo "=== Step 4/4: iPad English ==="
echo "アプリ内設定で言語を English に切替えてください。"
capture_interactive "$IPAD_UDID" "ipad" "en"

# Resize and generate
resize_all
generate_marketing

echo ""
echo "=== Complete ==="
echo "Marketing images: $SS_DIR/marketing/"
find "$SS_DIR/marketing" -name "*.png" | sort
echo ""
echo "To upload: python3 scripts/release.py submit"

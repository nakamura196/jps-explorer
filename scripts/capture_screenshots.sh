#!/bin/bash
set -euo pipefail

# JPS Explorer — Screenshot Capture & Marketing Image Pipeline
#
# Usage:
#   ./scripts/capture_screenshots.sh              # Interactive capture + marketing images
#   ./scripts/capture_screenshots.sh --auto       # Auto-capture via integration test
#   ./scripts/capture_screenshots.sh --marketing  # Marketing images only (skip capture)
#   ./scripts/capture_screenshots.sh --upload     # Generate + upload to App Store Connect

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots"
MARKETING_DIR="$SCREENSHOTS_DIR/marketing"

# Parse arguments
AUTO_MODE=false
MARKETING_ONLY=false
UPLOAD=false
LANG="ja"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --auto)     AUTO_MODE=true; shift ;;
        --marketing) MARKETING_ONLY=true; shift ;;
        --upload)   UPLOAD=true; shift ;;
        --lang)     LANG="$2"; shift 2 ;;
        --lang=*)   LANG="${1#*=}"; shift ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --auto       Auto-capture via Flutter integration test"
            echo "  --marketing  Skip capture, only generate marketing images"
            echo "  --upload     Generate + upload to App Store Connect"
            echo "  --lang LANG  Language for marketing text (ja|en, default: ja)"
            echo "  -h, --help   Show this help"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

mkdir -p "$SCREENSHOTS_DIR"
mkdir -p "$MARKETING_DIR"

# ---- Helper Functions ----

get_booted_udid() {
    xcrun simctl list devices booted -j 2>/dev/null \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d['state'] == 'Booted':
            print(d['udid'])
            sys.exit(0)
sys.exit(1)
" 2>/dev/null || true
}

take_screenshot() {
    local udid="$1"
    local name="$2"
    local path="$SCREENSHOTS_DIR/${name}.png"

    xcrun simctl io "$udid" screenshot "$path"
    echo "  Saved: $path"
}

resize_screenshots() {
    echo ""
    echo "=== Resizing for App Store (APP_IPHONE_67: 1290x2796) ==="
    for f in "$SCREENSHOTS_DIR"/*.png; do
        local base
        base="$(basename "$f")"
        # Skip already-resized or marketing images
        [[ "$base" == resized_* ]] && continue
        [[ "$base" == marketing_* ]] && continue

        local resized="$SCREENSHOTS_DIR/resized_${base}"
        sips -z 2796 1290 "$f" --out "$resized" >/dev/null 2>&1
        echo "  $base -> resized_${base}"
    done
}

# ---- Capture Modes ----

capture_interactive() {
    local udid="$1"
    echo ""
    echo "=== Interactive Screenshot Capture ==="
    echo "Navigate to each screen in the simulator, then press Enter."
    echo ""

    local screens=(
        "01_explore:探索画面 (Explore tab)"
        "02_search_results:検索結果画面 (Search results)"
        "03_detail:アイテム詳細画面 (Item detail)"
        "04_map:マップ画面 (Map tab)"
        "05_gallery:ギャラリー画面 (Gallery tab)"
    )

    for entry in "${screens[@]}"; do
        local name="${entry%%:*}"
        local desc="${entry#*:}"
        read -rp "  $desc を表示して Enter: " _
        take_screenshot "$udid" "$name"
    done
}

capture_auto() {
    local udid="$1"
    echo ""
    echo "=== Auto Screenshot Capture via Integration Test ==="
    echo "Device: $udid"
    echo ""

    # Run the Flutter integration test
    # The integration test uses binding.takeScreenshot() which saves to
    # the test output directory. We then copy them to our screenshots dir.
    cd "$PROJECT_DIR"

    echo "Running integration test..."
    flutter test integration_test/screenshot_test.dart -d "$udid" 2>&1 || {
        echo ""
        echo "Integration test failed or not available."
        echo "Falling back to simctl-based capture..."
        echo ""

        # Fallback: launch app and take screenshots with delays
        echo "Launching app..."
        flutter run -d "$udid" --no-hot &
        local flutter_pid=$!

        # Wait for app to load
        echo "Waiting for app to load (15 seconds)..."
        sleep 15

        # Take screenshots of whatever is on screen
        take_screenshot "$udid" "01_explore"

        echo "Waiting for screens... (take remaining screenshots manually)"
        echo "Press Enter after navigating to each screen."

        local remaining=(
            "02_search_results:検索結果画面"
            "03_detail:アイテム詳細画面"
            "04_map:マップ画面"
            "05_gallery:ギャラリー画面"
        )
        for entry in "${remaining[@]}"; do
            local name="${entry%%:*}"
            local desc="${entry#*:}"
            read -rp "  $desc を表示して Enter: " _
            take_screenshot "$udid" "$name"
        done

        # Stop the app
        kill "$flutter_pid" 2>/dev/null || true
        return
    }

    # If integration test succeeded, look for screenshots in build output
    # Flutter integration test screenshots end up in the build directory
    local build_screenshots
    build_screenshots=$(find "$PROJECT_DIR/build" -name "*.png" -newer "$PROJECT_DIR/pubspec.yaml" 2>/dev/null | head -20)

    if [[ -n "$build_screenshots" ]]; then
        echo "Copying screenshots from build output..."
        while IFS= read -r src; do
            local base
            base="$(basename "$src")"
            cp "$src" "$SCREENSHOTS_DIR/$base"
            echo "  Copied: $base"
        done <<< "$build_screenshots"
    fi
}

# ---- Main ----

echo "=== JPS Explorer — Screenshot Pipeline ==="
echo "Project: $PROJECT_DIR"
echo "Output:  $SCREENSHOTS_DIR"
echo ""

if [[ "$MARKETING_ONLY" == false ]]; then
    # Step 1: Find booted simulator
    echo "Looking for booted simulator..."
    UDID="$(get_booted_udid)"

    if [[ -z "$UDID" ]]; then
        echo "Error: No booted simulator found."
        echo ""
        echo "Boot a simulator first:"
        echo "  open -a Simulator"
        echo "  xcrun simctl boot 'iPhone 16 Pro Max'"
        echo ""
        echo "Or use --marketing to skip capture and only generate marketing images"
        echo "from existing screenshots."
        exit 1
    fi

    echo "Simulator: $UDID"

    # Step 2: Capture screenshots
    if [[ "$AUTO_MODE" == true ]]; then
        capture_auto "$UDID"
    else
        capture_interactive "$UDID"
    fi

    # Step 3: Resize
    resize_screenshots
fi

# Step 4: Generate marketing images
echo ""
echo "=== Generating Marketing Images ==="
python3 "$SCRIPT_DIR/generate_marketing_screenshots.py" \
    --input-dir "$SCREENSHOTS_DIR" \
    --output-dir "$MARKETING_DIR" \
    --lang "$LANG"

# Step 5: Optional upload
if [[ "$UPLOAD" == true ]]; then
    echo ""
    echo "=== Uploading to App Store Connect ==="
    python3 "$SCRIPT_DIR/release.py" submit
fi

echo ""
echo "=== Pipeline Complete ==="
echo ""
echo "Raw screenshots:      $SCREENSHOTS_DIR"
echo "Marketing images:     $MARKETING_DIR"
echo ""
echo "Next steps:"
echo "  - Review images in $MARKETING_DIR"
echo "  - Upload: python3 scripts/release.py submit"

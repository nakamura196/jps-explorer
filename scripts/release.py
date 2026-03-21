#!/usr/bin/env python3
"""
JPS Explorer — App Store Connect リリーススクリプト

Usage:
    # Step 1: ビルド & アップロード
    python3 scripts/release.py build

    # Step 2: スクリーンショット撮影
    python3 scripts/release.py screenshots

    # Step 3: メタデータ設定 & スクリーンショットアップロード & 審査提出
    python3 scripts/release.py submit
"""

import base64
import hashlib
import json
import os
import subprocess
import sys
import time
import urllib.request
import urllib.error

try:
    import jwt
except ImportError:
    print("PyJWT が必要です: pip install PyJWT cryptography")
    sys.exit(1)

# --- Config ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)

env_path = os.path.join(PROJECT_DIR, ".env")
env_vars = {}
if os.path.exists(env_path):
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                env_vars[k.strip()] = v.strip()

KEY_ID = env_vars.get("APP_STORE_API_KEY", os.environ.get("ASC_KEY_ID", ""))
ISSUER_ID = env_vars.get("APP_STORE_API_ISSUER", os.environ.get("ASC_ISSUER_ID", ""))
KEY_PATH = os.path.expanduser(f"~/.private_keys/AuthKey_{KEY_ID}.p8")
BUNDLE_ID = env_vars.get("BUNDLE_ID", "com.nakamura196.jpsExplorer")

SCREENSHOTS_DIR = os.path.join(PROJECT_DIR, "screenshots")

# App metadata
APP_NAME_JA = "JPS Explorer"
APP_NAME_EN = "JPS Explorer"
DESCRIPTION_JA = """ジャパンサーチの3,200万件以上の文化資源をモバイルで探索するアプリです。

主な機能:
・モチーフ検索 — 「鶴」「富士山」などテキストで画像を検索
・撮影画像で類似検索 — カメラで撮影した画像に似た文化資源を発見
・マップ探索 — 現在地周辺の文化資源を地図上に表示
・ギャラリー — キュレーションされたコレクションを閲覧
・お気に入り — 気になるアイテムをオフラインで保存
・本日の一品 — 毎日ランダムな文化資源を紹介
・周辺通知 — 近くに文化資源がある時に通知

ジャパンサーチ（https://jpsearch.go.jp）のWeb APIを使用しています。"""

DESCRIPTION_EN = """Explore over 32 million cultural resources from Japan Search on your mobile device.

Key features:
- Motif Search — Find images by describing what you see ("crane", "Mt. Fuji")
- Photo Similarity Search — Take a photo and find similar cultural resources
- Map Exploration — Discover cultural resources near your current location
- Gallery — Browse curated collections
- Favorites — Save items for offline viewing
- Today's Pick — A random cultural resource each day
- Nearby Notifications — Get notified when cultural resources are nearby

Powered by Japan Search (https://jpsearch.go.jp) Web API."""

KEYWORDS_JA = "ジャパンサーチ,文化資源,デジタルアーカイブ,浮世絵,古地図,美術,博物館,図書館"
KEYWORDS_EN = "Japan Search,cultural heritage,digital archive,ukiyo-e,museum,library,art"
PROMO_JA = "ジャパンサーチの3,200万件以上の文化資源をモバイルで探索。モチーフ検索、撮影画像での類似検索、マップ探索など。"
PROMO_EN = "Explore over 32 million cultural resources from Japan Search. Motif search, photo similarity search, map exploration, and more."
SUPPORT_URL = env_vars.get("SUPPORT_URL", "https://jpsearch.go.jp")
COPYRIGHT = env_vars.get("COPYRIGHT", "2026 Satoru Nakamura")
PRIVACY_URL = env_vars.get("PRIVACY_URL", "https://nakamura196.pages.dev/ja/privacy/")
PRIVACY_URL_EN = env_vars.get("PRIVACY_URL_EN", "https://nakamura196.pages.dev/en/privacy/")

# Review contact (from .env)
CONTACT_FIRST_NAME = env_vars.get("CONTACT_FIRST_NAME", "Satoru")
CONTACT_LAST_NAME = env_vars.get("CONTACT_LAST_NAME", "Nakamura")
CONTACT_EMAIL = env_vars.get("CONTACT_EMAIL", "nakamura@hi.u-tokyo.ac.jp")
CONTACT_PHONE = env_vars.get("CONTACT_PHONE", "+81-90-0000-0000")


def generate_token():
    with open(KEY_PATH) as f:
        private_key = f.read()
    now = int(time.time())
    payload = {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})


def api_request(method, path, data=None):
    token = generate_token()
    url = f"https://api.appstoreconnect.apple.com/v1/{path}"
    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(url, data=body, method=method, headers={
        "Authorization": f"Bearer {token}", "Content-Type": "application/json"
    })
    try:
        resp = urllib.request.urlopen(req)
        if resp.status == 204:
            return None
        return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        print(f"  Error {e.code}: {e.read().decode()[:500]}")
        raise


# === Step 1: Build & Upload ===

def cmd_build():
    print("=== JPS Explorer — Build & Upload ===\n")

    # Flutter build
    print("[1/3] Building iOS archive...")
    subprocess.run([
        "flutter", "build", "ipa",
        "--export-method", "app-store",
    ], cwd=PROJECT_DIR, check=True)

    ipa_path = os.path.join(PROJECT_DIR, "build", "ios", "ipa", "jps_explorer.ipa")
    if not os.path.exists(ipa_path):
        # Try to find ipa
        import glob
        ipas = glob.glob(os.path.join(PROJECT_DIR, "build", "ios", "ipa", "*.ipa"))
        if ipas:
            ipa_path = ipas[0]
        else:
            print("Error: IPA not found")
            sys.exit(1)

    print(f"  IPA: {ipa_path}")

    # Upload
    print("\n[2/3] Uploading to App Store Connect...")
    subprocess.run([
        "xcrun", "altool", "--upload-app",
        "--type", "ios",
        "--file", ipa_path,
        "--apiKey", KEY_ID,
        "--apiIssuer", ISSUER_ID,
    ], check=True)

    print("\n[3/3] Upload complete! Wait for processing in App Store Connect.")
    print("  Processing usually takes 10-30 minutes.")
    print("  Then run: python3 scripts/release.py submit")


# === Step 2: Screenshots ===

def cmd_screenshots():
    print("=== JPS Explorer — Screenshot Capture ===\n")
    os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

    device_id = subprocess.run(
        ["xcrun", "simctl", "list", "devices", "booted", "-j"],
        capture_output=True, text=True
    ).stdout
    devices = json.loads(device_id)
    booted = None
    for runtime, device_list in devices.get("devices", {}).items():
        for d in device_list:
            if d["state"] == "Booted":
                booted = d["udid"]
                break

    if not booted:
        print("Error: No booted simulator found")
        sys.exit(1)

    print(f"Device: {booted}")
    print("Taking screenshots... Navigate to each screen and press Enter.\n")

    screens = [
        ("01_explore", "探索画面（検索結果表示中）"),
        ("02_detail", "アイテム詳細画面"),
        ("03_map", "マップ画面（検索結果表示中）"),
        ("04_gallery", "ギャラリー画面"),
        ("05_camera", "カメラ検索画面"),
    ]

    for filename, description in screens:
        input(f"  {description} を表示して Enter: ")
        path = os.path.join(SCREENSHOTS_DIR, f"{filename}.png")
        subprocess.run([
            "xcrun", "simctl", "io", booted, "screenshot", path
        ], check=True)
        print(f"    Saved: {path}")

    # Resize for App Store
    print("\nResizing for App Store (APP_IPHONE_67: 1290x2796)...")
    for f in os.listdir(SCREENSHOTS_DIR):
        if f.endswith(".png"):
            path = os.path.join(SCREENSHOTS_DIR, f)
            resized = os.path.join(SCREENSHOTS_DIR, f"resized_{f}")
            subprocess.run([
                "sips", "-z", "2796", "1290", path, "--out", resized
            ], check=True)
            print(f"  {f} → resized_{f}")

    print(f"\nScreenshots saved to: {SCREENSHOTS_DIR}")


# === Step 3: Submit ===

def cmd_submit():
    print("=== JPS Explorer — App Store Submit ===\n")

    # 1. Get App ID
    print("[1/10] Getting App ID...")
    result = api_request("GET", f"apps?filter[bundleId]={BUNDLE_ID}")
    if not result["data"]:
        print(f"  App not found for bundle ID: {BUNDLE_ID}")
        print("  Create the app in App Store Connect first.")
        sys.exit(1)
    APP_ID = result["data"][0]["id"]
    print(f"  App ID: {APP_ID}")

    # 2. Get Version
    print("\n[2/10] Getting version...")
    result = api_request("GET",
        f"apps/{APP_ID}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION")
    if not result["data"]:
        print("  No version in PREPARE_FOR_SUBMISSION state.")
        print("  Create a new version in App Store Connect first.")
        sys.exit(1)
    VERSION_ID = result["data"][0]["id"]
    print(f"  Version ID: {VERSION_ID}")

    # 3. Get/Create Localizations
    print("\n[3/10] Setting up localizations...")
    result = api_request("GET",
        f"appStoreVersions/{VERSION_ID}/appStoreVersionLocalizations")
    locs = {loc["attributes"]["locale"]: loc["id"] for loc in result["data"]}

    for locale in ["ja", "en-US"]:
        if locale not in locs:
            r = api_request("POST", "appStoreVersionLocalizations", {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": {"locale": locale},
                    "relationships": {
                        "appStoreVersion": {
                            "data": {"type": "appStoreVersions", "id": VERSION_ID}
                        }
                    }
                }
            })
            locs[locale] = r["data"]["id"]
            print(f"  Created: {locale}")

    JA_LOC = locs.get("ja", locs.get("ja-JP"))
    EN_LOC = locs.get("en-US", locs.get("en-GB", locs.get("en")))
    print(f"  ja: {JA_LOC}, en: {EN_LOC}")

    # 4. Set Metadata
    print("\n[4/10] Setting metadata...")
    if JA_LOC:
        api_request("PATCH", f"appStoreVersionLocalizations/{JA_LOC}", {
            "data": {
                "type": "appStoreVersionLocalizations", "id": JA_LOC,
                "attributes": {
                    "description": DESCRIPTION_JA, "keywords": KEYWORDS_JA,
                    "promotionalText": PROMO_JA, "supportUrl": SUPPORT_URL,
                }
            }
        })
        print("  ja: OK")

    if EN_LOC:
        api_request("PATCH", f"appStoreVersionLocalizations/{EN_LOC}", {
            "data": {
                "type": "appStoreVersionLocalizations", "id": EN_LOC,
                "attributes": {
                    "description": DESCRIPTION_EN, "keywords": KEYWORDS_EN,
                    "promotionalText": PROMO_EN, "supportUrl": SUPPORT_URL,
                }
            }
        })
        print("  en: OK")

    # 5. Upload Screenshots (marketing images)
    print("\n[5/10] Uploading screenshots...")
    marketing_dirs = {
        JA_LOC: os.path.join(SCREENSHOTS_DIR, "marketing", "ja"),
        EN_LOC: os.path.join(SCREENSHOTS_DIR, "marketing", "en"),
    }

    any_uploaded = False
    for loc_id, mdir in marketing_dirs.items():
        if not loc_id or not os.path.exists(mdir):
            continue
        files = sorted([f for f in os.listdir(mdir) if f.endswith(".png")])
        if not files:
            continue
        ss_set_id = create_screenshot_set(loc_id)
        for f in files:
            filepath = os.path.join(mdir, f)
            print(f"  Uploading {f} ({os.path.basename(mdir)})...")
            upload_screenshot(ss_set_id, filepath, f)
            any_uploaded = True

    if not any_uploaded:
        print("  No marketing images found. Run './scripts/capture_screenshots.sh' first.")

    # 6. Age Rating
    print("\n[6/10] Setting age rating...")
    result = api_request("GET", f"apps/{APP_ID}/appInfos")
    APP_INFO_ID = result["data"][0]["id"]
    api_request("PATCH", f"ageRatingDeclarations/{APP_INFO_ID}", {
        "data": {
            "type": "ageRatingDeclarations", "id": APP_INFO_ID,
            "attributes": {
                "alcoholTobaccoOrDrugUseOrReferences": "NONE",
                "contests": "NONE", "gamblingSimulated": "NONE",
                "gunsOrOtherWeapons": "NONE", "horrorOrFearThemes": "NONE",
                "matureOrSuggestiveThemes": "NONE",
                "medicalOrTreatmentInformation": "NONE",
                "profanityOrCrudeHumor": "NONE",
                "sexualContentGraphicAndNudity": "NONE",
                "sexualContentOrNudity": "NONE",
                "violenceCartoonOrFantasy": "NONE",
                "violenceRealistic": "NONE",
                "violenceRealisticProlongedGraphicOrSadistic": "NONE",
                "gambling": False, "lootBox": False,
                "unrestrictedWebAccess": False, "messagingAndChat": False,
                "ageAssurance": False, "advertising": False,
                "parentalControls": False, "userGeneratedContent": False,
                "healthOrWellnessTopics": False,
            }
        }
    })
    print("  Age rating: 4+")

    # 7. Privacy URL & Category
    print("\n[7/10] Setting privacy URL & category...")
    info_locs = api_request("GET", f"appInfos/{APP_INFO_ID}/appInfoLocalizations")
    for loc in info_locs["data"]:
        api_request("PATCH", f"appInfoLocalizations/{loc['id']}", {
            "data": {
                "type": "appInfoLocalizations", "id": loc["id"],
                "attributes": {"privacyPolicyUrl": PRIVACY_URL}
            }
        })

    api_request("PATCH", f"appInfos/{APP_INFO_ID}", {
        "data": {
            "type": "appInfos", "id": APP_INFO_ID,
            "relationships": {
                "primaryCategory": {"data": {"type": "appCategories", "id": "REFERENCE"}},
                "secondaryCategory": {"data": {"type": "appCategories", "id": "EDUCATION"}},
            }
        }
    })
    print("  Categories: Reference / Education")

    # 8. Copyright & Content Rights
    print("\n[8/10] Setting copyright & content rights...")
    api_request("PATCH", f"appStoreVersions/{VERSION_ID}", {
        "data": {
            "type": "appStoreVersions", "id": VERSION_ID,
            "attributes": {"copyright": COPYRIGHT}
        }
    })
    api_request("PATCH", f"apps/{APP_ID}", {
        "data": {
            "type": "apps", "id": APP_ID,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"}
        }
    })
    print("  OK")

    # 9. Build association & encryption
    print("\n[9/10] Associating build...")
    builds = api_request("GET", f"builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=5")
    valid_build = None
    for build in builds["data"]:
        if build["attributes"]["processingState"] == "VALID":
            valid_build = build
            break

    if not valid_build:
        print("  No valid build found. Wait for processing and retry.")
        return

    BUILD_ID = valid_build["id"]
    print(f"  Build: {valid_build['attributes']['version']} ({BUILD_ID})")

    api_request("PATCH", f"appStoreVersions/{VERSION_ID}/relationships/build", {
        "data": {"type": "builds", "id": BUILD_ID}
    })
    api_request("PATCH", f"builds/{BUILD_ID}", {
        "data": {
            "type": "builds", "id": BUILD_ID,
            "attributes": {"usesNonExemptEncryption": False}
        }
    })
    print("  Build associated, encryption compliance set")

    # 10. Review details & Submit
    print("\n[10/10] Creating review details & submitting...")
    try:
        api_request("POST", "appStoreReviewDetails", {
            "data": {
                "type": "appStoreReviewDetails",
                "attributes": {
                    "contactFirstName": CONTACT_FIRST_NAME,
                    "contactLastName": CONTACT_LAST_NAME,
                    "contactEmail": CONTACT_EMAIL,
                    "contactPhone": CONTACT_PHONE,
                    "demoAccountRequired": False,
                    "demoAccountName": "",
                    "demoAccountPassword": "",
                    "notes": "This app uses Japan Search (jpsearch.go.jp) public API."
                },
                "relationships": {
                    "appStoreVersion": {
                        "data": {"type": "appStoreVersions", "id": VERSION_ID}
                    }
                }
            }
        })
    except Exception:
        print("  Review details may already exist, continuing...")

    # Submit
    result = api_request("POST", "reviewSubmissions", {
        "data": {
            "type": "reviewSubmissions",
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}}
            }
        }
    })
    SUBMISSION_ID = result["data"]["id"]

    api_request("POST", "reviewSubmissionItems", {
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": SUBMISSION_ID}},
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": VERSION_ID}}
            }
        }
    })

    api_request("PATCH", f"reviewSubmissions/{SUBMISSION_ID}", {
        "data": {
            "type": "reviewSubmissions", "id": SUBMISSION_ID,
            "attributes": {"submitted": True}
        }
    })
    print("  Submitted for review!")
    print("\n=== Done! Check App Store Connect for review status. ===")


def create_screenshot_set(localization_id, display_type="APP_IPHONE_67"):
    result = api_request("GET",
        f"appStoreVersionLocalizations/{localization_id}/appScreenshotSets")
    for ss_set in result["data"]:
        if ss_set["attributes"]["screenshotDisplayType"] == display_type:
            return ss_set["id"]

    result = api_request("POST", "appScreenshotSets", {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": display_type},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": localization_id}
                }
            }
        }
    })
    return result["data"]["id"]


def upload_screenshot(screenshot_set_id, filepath, filename):
    with open(filepath, "rb") as f:
        file_data = f.read()

    checksum = base64.b64encode(hashlib.md5(file_data).digest()).decode()

    result = api_request("POST", "appScreenshots", {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": filename, "fileSize": len(file_data)},
            "relationships": {
                "appScreenshotSet": {
                    "data": {"type": "appScreenshotSets", "id": screenshot_set_id}
                }
            }
        }
    })

    screenshot_id = result["data"]["id"]
    upload_ops = result["data"]["attributes"]["uploadOperations"]

    for op in upload_ops:
        chunk = file_data[op["offset"]:op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], data=chunk, method=op["method"])
        for h in op["requestHeaders"]:
            req.add_header(h["name"], h["value"])
        urllib.request.urlopen(req)

    api_request("PATCH", f"appScreenshots/{screenshot_id}", {
        "data": {
            "type": "appScreenshots", "id": screenshot_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": checksum}
        }
    })
    print(f"    OK: {filename}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(0)

    cmd = sys.argv[1]
    if cmd == "build":
        cmd_build()
    elif cmd == "screenshots":
        cmd_screenshots()
    elif cmd == "submit":
        cmd_submit()
    else:
        print(f"Unknown command: {cmd}")
        print("Commands: build, screenshots, submit")

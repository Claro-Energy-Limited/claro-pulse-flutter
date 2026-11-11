#!/usr/bin/env bash
# Builds the App Store upload (.ipa) of Claro Pulse (Flutter). Runs on a MAC ONLY: Apple allows
# iOS builds nowhere else. The Android scripts (*.ps1) are the Windows equivalents.
#
# First run on a Mac adds the ios/ folder (this project started Android-only), sets the bundle ID
# to in.claroenergy.claropulse (same as Android), the camera permission text for the QR scanner,
# and the minimum iOS version mobile_scanner needs. Commit the ios/ folder it creates.
#
# Before the first run, once:
#   - Xcode from the App Store, then: sudo xcode-select -s /Applications/Xcode.app && sudo xcodebuild -license accept
#   - CocoaPods: brew install cocoapods
#   - Apple Developer account (US$99/yr), and the app created in App Store Connect with bundle ID
#     in.claroenergy.claropulse
#   - open ios/Runner.xcworkspace in Xcode -> Runner -> Signing & Capabilities -> tick
#     "Automatically manage signing" and pick the Claro Energy team
#
# Usage:
#   ./build-ios.sh                      # next build number
#   ./build-ios.sh --build-number 5     # realign with App Store Connect
#   ./build-ios.sh --version-name 2.1.0 # default 2.0.<build number>
set -euo pipefail

cd "$(dirname "$0")"

PROD_API_BASE_URL="https://pulse-api.claroenergy.in/app/v1/"
MIN_IOS="15.5"   # mobile_scanner 7 needs at least this
CAMERA_TEXT="Claro Pulse uses the camera to scan the QR code on your device."
VERSION_FILE=".release-version-ios"

BUILD_NUMBER=""
VERSION_NAME=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-number) BUILD_NUMBER="$2"; shift 2 ;;
    --version-name) VERSION_NAME="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ "$(uname)" != "Darwin" ]]; then
  echo "iOS builds only work on a Mac. On Windows use build-release-aab.ps1 for Android." >&2
  exit 1
fi
command -v flutter >/dev/null || { echo "flutter not found. Install it: https://docs.flutter.dev/get-started/install/macos/mobile-ios" >&2; exit 1; }
command -v pod >/dev/null || { echo "CocoaPods not found. Run: brew install cocoapods" >&2; exit 1; }

# -- First run: add the iOS project --------------------------------------------------------------
if [[ ! -d ios ]]; then
  echo "Adding the iOS project (first run on a Mac)..."
  # --org + the pubspec name 'claropulse' give bundle ID in.claroenergy.claropulse.
  flutter create --platforms=ios --org in.claroenergy .
fi

PLIST="ios/Runner/Info.plist"
if ! /usr/libexec/PlistBuddy -c "Print :NSCameraUsageDescription" "$PLIST" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Add :NSCameraUsageDescription string $CAMERA_TEXT" "$PLIST"
fi
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Claro Pulse" "$PLIST" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Claro Pulse" "$PLIST"

sed -i '' -E "s/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;/IPHONEOS_DEPLOYMENT_TARGET = ${MIN_IOS};/g" ios/Runner.xcodeproj/project.pbxproj

flutter pub get
# Writes ios/Podfile if it does not exist yet.
flutter build ios --config-only --no-codesign >/dev/null

PODFILE="ios/Podfile"
sed -i '' -E "s/^#? *platform :ios, '[0-9.]+'/platform :ios, '${MIN_IOS}'/" "$PODFILE"
# permission_handler compiles out every permission not switched on here; without this the
# camera request silently returns "denied" on iOS.
if ! grep -q "PERMISSION_CAMERA=1" "$PODFILE"; then
  perl -0pi -e "s/(flutter_additional_ios_build_settings\(target\)\n)/\$1    target.build_configurations.each do |config|\n      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['\\\$(inherited)', 'PERMISSION_CAMERA=1']\n    end\n/" "$PODFILE"
fi
(cd ios && pod install)

# -- Version --------------------------------------------------------------------------------------
LAST=0
[[ -f "$VERSION_FILE" ]] && LAST="$(tr -dc '0-9' < "$VERSION_FILE")"
[[ -z "$LAST" ]] && LAST=0
[[ -z "$BUILD_NUMBER" ]] && BUILD_NUMBER=$((LAST + 1))
[[ -z "$VERSION_NAME" ]] && VERSION_NAME="2.0.${BUILD_NUMBER}"
echo "Building iOS version ${VERSION_NAME} (${BUILD_NUMBER}) against ${PROD_API_BASE_URL}, fake data OFF"

# -- Checks + build -------------------------------------------------------------------------------
flutter analyze
flutter test
flutter build ipa --release \
  --build-number="$BUILD_NUMBER" --build-name="$VERSION_NAME" \
  --dart-define=MOCK_API=false --dart-define=API_BASE_URL="$PROD_API_BASE_URL"

IPA="$(ls build/ios/ipa/*.ipa | head -n 1)"
mkdir -p releases
OUT="releases/ClaroPulse-ios-v${BUILD_NUMBER}-${VERSION_NAME}-$(date +%Y%m%d-%H%M).ipa"
cp "$IPA" "$OUT"
printf '%s' "$BUILD_NUMBER" > "$VERSION_FILE"

echo
echo "Done. IPA ready: $OUT"
echo "Upload it with the Transporter app (Mac App Store), then App Store Connect -> TestFlight to try it on an iPhone."

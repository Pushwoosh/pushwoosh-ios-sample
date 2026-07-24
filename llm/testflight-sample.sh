#!/usr/bin/env bash
# testflight-sample.sh — Pushwoosh iOS sample: temporary bundle-id swap → archive →
#   export → upload to TestFlight → revert. project.pbxproj is restored byte-for-byte on
#   EXIT (success, failure, Ctrl-C), so the repo bundle id is never left changed.
#   Marketing version and build number are applied as xcodebuild overrides (no pbxproj edit),
#   so every upload is unique and won't be rejected by App Store Connect.
#
# This script is self-contained and path-relative — clone the repo, add your creds
# (see llm/testflight-publish.md), and run it. No secrets live in the repo.
#
# Usage (run from anywhere):
#   llm/testflight-sample.sh                 # swap → archive → export → upload → revert
#   llm/testflight-sample.sh --dry-run       # swap → archive → export → revert (NO upload)
#   llm/testflight-sample.sh --version 7.2.0 # force marketing version (else auto-bump patch)
#
# Version: --version X.Y.Z wins; otherwise bump the patch of the last used version
#   (persisted in llm/.testflight.version, seeded from the project). Build number is
#   always a fresh timestamp.
#
# Auth (App Store Connect API key), required for upload (not for --dry-run):
#   export ASC_KEY_ID=XXXXXXXX ASC_ISSUER_ID=xxxxxxxx-xxxx-...
#   (or copy llm/.testflight.env.example → llm/.testflight.env and fill it in)
#   .p8 key at ~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8
#   (or point ASC_KEY_PATH at the .p8 explicitly)
#
# Overridable env: PW_SAMPLE_DIR, PW_TEAM_ID, PW_EXPORT_METHOD, ASC_KEY_PATH
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PW_SAMPLE_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
WORKSPACE="PushwooshSampleApp.xcworkspace"
SCHEME="PushwooshSampleApp"
TEAM_ID="${PW_TEAM_ID:-EZ696X67SZ}"
BUNDLE_PREFIX="com.pushwoosh.PushwooshSampleApp"
PROD_SUFFIX="Prod"
EXPORT_METHOD="${PW_EXPORT_METHOD:-app-store-connect}"   # older Xcode: app-store
PBXPROJ="$PROJECT_DIR/PushwooshSampleApp.xcodeproj/project.pbxproj"
VERSION_STATE="$SCRIPT_DIR/.testflight.version"

DRY_RUN=0
VERSION_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --version) shift; VERSION_ARG="${1:-}"; [ -n "$VERSION_ARG" ] || { echo "--version needs X.Y.Z" >&2; exit 2; } ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1 (use --dry-run / --version X.Y.Z / --help)" >&2; exit 2 ;;
  esac
  shift
done

fail() { echo "❌ $*" >&2; exit 1; }
bump_patch() { local v="$1"; local IFS=.; read -ra P <<< "$v"; local n=${#P[@]}; P[$((n-1))]=$(( ${P[$((n-1))]} + 1 )); echo "${P[*]}"; }

# ---------- preflight ----------
command -v xcodebuild >/dev/null || fail "xcodebuild not found"
[ -f "$PBXPROJ" ] || fail "pbxproj not found: $PBXPROJ"

ENV_FILE="$SCRIPT_DIR/.testflight.env"
[ -f "$ENV_FILE" ] && { set -a; . "$ENV_FILE"; set +a; }

P8="${ASC_KEY_PATH:-}"
[ -z "$P8" ] && [ -n "${ASC_KEY_ID:-}" ] && P8="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
if [ "$DRY_RUN" -eq 0 ]; then
  [ -n "${ASC_KEY_ID:-}" ]    || fail "ASC_KEY_ID not set (env or $ENV_FILE — see llm/testflight-publish.md)"
  [ -n "${ASC_ISSUER_ID:-}" ] || fail "ASC_ISSUER_ID not set (env or $ENV_FILE)"
  [ -f "$P8" ]                || fail "ASC key not found: $P8 (set ASC_KEY_PATH or place AuthKey_<ID>.p8 there)"
fi

# ---------- resolve marketing version + build number ----------
if [ -n "$VERSION_ARG" ]; then
  VERSION="$VERSION_ARG"
else
  if [ -f "$VERSION_STATE" ]; then
    BASE="$(cat "$VERSION_STATE")"
  else
    BASE="$(grep -m1 -oE 'MARKETING_VERSION = [^;]+;' "$PBXPROJ" | sed -E 's/MARKETING_VERSION = ([^;]+);/\1/')"
    [ -n "$BASE" ] || BASE="1.0"
  fi
  VERSION="$(bump_patch "$BASE")"
fi
BUILD_NUMBER="$(date +%Y%m%d%H%M%S)"

# ---------- snapshot + guaranteed revert ----------
BACKUP="$(mktemp)"
WORKDIR="$(mktemp -d)"
cp "$PBXPROJ" "$BACKUP"
cleanup() {
  cp "$BACKUP" "$PBXPROJ"
  rm -f "$BACKUP"
  rm -rf "$WORKDIR"
  echo "↩︎  project.pbxproj restored; temp cleaned"
}
trap cleanup EXIT

# ---------- swap bundle id (PRODUCT_BUNDLE_IDENTIFIER lines only; keeps nesting; leaves tests) ----------
PREFIX_RE="$(printf '%s' "$BUNDLE_PREFIX" | sed 's/\./\\./g')"
sed -i '' -E "s/(PRODUCT_BUNDLE_IDENTIFIER = ${PREFIX_RE})/\1${PROD_SUFFIX}/" "$PBXPROJ"
CHANGED="$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = ${BUNDLE_PREFIX}${PROD_SUFFIX}" "$PBXPROJ" || true)"
[ "$CHANGED" -gt 0 ] || fail "bundle-id swap changed nothing — prefix mismatch?"
echo "✓ swapped $CHANGED bundle id(s) → ${BUNDLE_PREFIX}${PROD_SUFFIX}*"
echo "✓ version $VERSION, build $BUILD_NUMBER"

AUTH=()
if [ -n "${ASC_KEY_ID:-}" ] && [ -f "$P8" ]; then
  AUTH=(-authenticationKeyPath "$P8" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

cd "$PROJECT_DIR"

# ---------- archive ----------
ARCHIVE="$WORKDIR/PushwooshSampleApp.xcarchive"
echo "▶ archiving…"
xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -configuration Release \
  -destination "generic/platform=iOS" -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"} \
  MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  archive

# ---------- export ----------
EXPORT_OPTS="$WORKDIR/ExportOptions.plist"
cat > "$EXPORT_OPTS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>${EXPORT_METHOD}</string>
  <key>teamID</key><string>${TEAM_ID}</string>
  <key>signingStyle</key><string>automatic</string>
  <key>destination</key><string>export</string>
</dict></plist>
PLIST
echo "▶ exporting…"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$WORKDIR/export" \
  -exportOptionsPlist "$EXPORT_OPTS" \
  -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"}
IPA="$(find "$WORKDIR/export" -name '*.ipa' | head -1)"
[ -n "$IPA" ] && [ -f "$IPA" ] || fail "no .ipa produced"
echo "✓ exported: $(basename "$IPA")"

# ---------- upload ----------
if [ "$DRY_RUN" -eq 1 ]; then
  KEEP="$PROJECT_DIR/build/testflight-dryrun.ipa"
  mkdir -p "$(dirname "$KEEP")"
  cp "$IPA" "$KEEP"
  echo "🔎 --dry-run: upload skipped. IPA kept at $KEEP"
else
  echo "▶ uploading to TestFlight…"
  xcrun altool --upload-app --type ios --file "$IPA" \
    --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
  printf '%s' "$VERSION" > "$VERSION_STATE"
  echo "🚀 uploaded: ${BUNDLE_PREFIX}${PROD_SUFFIX} v$VERSION (build $BUILD_NUMBER)"
fi
# trap restores project.pbxproj here

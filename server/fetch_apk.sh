#!/bin/sh
set -eu
mkdir -p downloads
NOTES="$(dirname "$0")/install_notes"
LATEST="https://github.com/GerardoRosas-27/naves-arcade/releases/latest/download/naves-arcade.apk"
TAGGED="https://github.com/GerardoRosas-27/naves-arcade/releases/download/v1.0.1-mobile/naves-arcade.apk"
echo Fetching_APK
if ! curl -fL --retry 3 --retry-delay 2 -o downloads/naves-arcade.apk "$LATEST"; then
  echo fallback_tagged
  curl -fL --retry 3 --retry-delay 2 -o downloads/naves-arcade.apk "$TAGGED"
fi
test -s downloads/naves-arcade.apk
ls -lh downloads/naves-arcade.apk
TMP_A=$(mktemp -d)
cp downloads/naves-arcade.apk "$TMP_A/naves-arcade.apk"
cp "$NOTES/INSTALL_ANDROID.txt" "$TMP_A/INSTALL_ANDROID.txt"
(cd "$TMP_A" && zip -q -r /app/downloads/naves-arcade-android.zip naves-arcade.apk INSTALL_ANDROID.txt)
rm -rf "$TMP_A"
ls -lh downloads/naves-arcade-android.zip
TMP_I=$(mktemp -d)
cp "$NOTES/INSTALL_IOS.txt" "$TMP_I/INSTALL_IOS.txt"
(cd "$TMP_I" && zip -q -r /app/downloads/naves-arcade-ios.zip INSTALL_IOS.txt)
rm -rf "$TMP_I"
ls -lh downloads/naves-arcade-ios.zip

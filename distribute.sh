#!/bin/bash
set -e

PUBSPEC="pubspec.yaml"
FLUTTER="/Users/handenur.coskun/development/flutter/bin/flutter"
FIREBASE="$HOME/.npm-global/bin/firebase"
APP_ID="1:508106937166:android:6210f6e007690c4eaac41f"
TESTER="handenurcokun@gmail.com,tabiattanbiri@gmail.com"

# Mevcut versiyonu oku ve build numarasını artır
CURRENT=$(grep "^version:" $PUBSPEC | sed 's/version: //')
VERSION_NAME=$(echo $CURRENT | cut -d'+' -f1)
BUILD_NUM=$(echo $CURRENT | cut -d'+' -f2)
NEW_BUILD=$((BUILD_NUM + 1))
NEW_VERSION="${VERSION_NAME}+${NEW_BUILD}"

# pubspec.yaml güncelle
sed -i '' "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC
echo "Versiyon: $NEW_VERSION"

# Build al
$FLUTTER build apk --release

# Dağıt
NOTE="${1:-Güncelleme}"
$FIREBASE appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app $APP_ID \
  --testers "$TESTER" \
  --release-notes "$NOTE ($NEW_VERSION)"

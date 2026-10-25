#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Air Traffic Control"
EXECUTABLE="AirTrafficControl"
BUILD_APP="build/$APP_NAME.app"
DEST="$HOME/Applications/$APP_NAME.app"
CONFIG_DIR="$HOME/.config/air-traffic-control"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

rm -rf build
mkdir -p "$BUILD_APP/Contents/MacOS" "$BUILD_APP/Contents/Resources"
cp Info.plist "$BUILD_APP/Contents/Info.plist"

ICONSET="build/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" Resources/AppIcon.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  sips -z "$((size * 2))" "$((size * 2))" Resources/AppIcon.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$BUILD_APP/Contents/Resources/AppIcon.icns"

xcrun swiftc -O -o "$BUILD_APP/Contents/MacOS/$EXECUTABLE" Sources/main.swift
codesign --force --sign - "$BUILD_APP"

pkill -x "$EXECUTABLE" || true
mkdir -p "$HOME/Applications"
rm -rf "$DEST"
cp -R "$BUILD_APP" "$DEST"
"$LSREGISTER" -f "$DEST"
"$LSREGISTER" -u "$BUILD_APP"
rm -rf build

mkdir -p "$CONFIG_DIR"
LIVE_RULES="$CONFIG_DIR/rules.json"
if [ ! -f rules.json ]; then
  if [ -f "$LIVE_RULES" ] && [ ! -L "$LIVE_RULES" ]; then
    mv "$LIVE_RULES" rules.json
    echo "Moved $LIVE_RULES to rules.json"
  else
    cp rules.example.json rules.json
    echo "Created rules.json from rules.example.json"
  fi
fi
ln -sfn "$PWD/rules.json" "$LIVE_RULES"

echo "Installed $DEST"
echo "Next: System Settings > Desktop & Dock > Default web browser > $APP_NAME"

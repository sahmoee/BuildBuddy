#!/bin/bash
# ============================================================================
# Launch BuildBuddy — compiles the SwiftUI app (first run) and opens it.
# Double-click this file. No Xcode project needed; it builds a real .app for you.
# ============================================================================
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="BuildBuddy"
SRC="$DIR/$APP_NAME.swift"
BUILD="$DIR/.build"
APP="$BUILD/$APP_NAME.app"
MACOS="$APP/Contents/MacOS"
BIN="$MACOS/$APP_NAME"

echo "BuildBuddy launcher"
echo "==================="

# 1. Need the Swift compiler (ships with Xcode / Command Line Tools).
if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo "Swift compiler not found. Installing Apple Command Line Tools…"
  echo "A system dialog will appear — click Install, wait for it to finish, then run this again."
  xcode-select --install 2>/dev/null
  exit 1
fi

# 2. (Re)build only when the source is newer than the binary.
need_build=1
if [ -f "$BIN" ] && [ "$BIN" -nt "$SRC" ]; then need_build=0; fi

if [ "$need_build" -eq 1 ]; then
  echo "Building $APP_NAME (first run or source changed)…"
  mkdir -p "$MACOS" "$APP/Contents/Resources"
  if ! xcrun swiftc -O -parse-as-library "$SRC" -o "$BIN" 2>"$BUILD/build.log"; then
    echo "❌ Build failed. Details:"
    cat "$BUILD/build.log"
    echo
    echo "Copy the errors above and send them to Claude — it'll patch BuildBuddy.swift."
    exit 1
  fi

  # Minimal Info.plist so it launches as a proper windowed app.
  cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>com.sowens.buildbuddy</string>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleVersion</key><string>6</string>
  <key>CFBundleShortVersionString</key><string>1.5</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
  echo -n 'APPL' > "$APP/Contents/PkgInfo"
  echo "✅ Built."
fi

# 3. Locally-built app has no quarantine, but strip it just in case.
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

echo "Opening $APP_NAME…"
open "$APP"

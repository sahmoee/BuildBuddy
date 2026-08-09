#!/bin/bash
# ============================================================================
# Build BuildBuddy.app — produces a standalone, permanent Mac app.
#
# Double-click this ONCE. It compiles BuildBuddy.swift into a real .app with an
# icon and a stable signed identity, then offers to install it to /Applications.
#
# The result behaves like any other Mac app: launch from Launchpad/Spotlight,
# pin to the Dock, no Terminal needed afterward. All current capabilities are
# preserved — the app is NOT sandboxed, so it keeps full git / shell access to
# your repos under ~/Documents/. No Xcode project, no packages.
# ============================================================================
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="BuildBuddy"
SRC="$DIR/$APP_NAME.swift"
APP="$DIR/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"
BIN="$MACOS/$APP_NAME"
BUNDLE_ID="com.sowens.buildbuddy"
SHORT_VERSION="2.0"
BUILD_VERSION="21"

echo "BuildBuddy — full app builder"
echo "============================="

# ----------------------------------------------------------------------------
# 0. Sanity: source present.
# ----------------------------------------------------------------------------
if [ ! -f "$SRC" ]; then
  echo "Could not find $APP_NAME.swift next to this script."
  echo "Keep 'Build BuildBuddy.app.command' in the same folder as BuildBuddy.swift."
  exit 1
fi

# ----------------------------------------------------------------------------
# 1. Need the Swift compiler (ships with Xcode / Command Line Tools).
# ----------------------------------------------------------------------------
if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo "Swift compiler not found. Installing Apple Command Line Tools..."
  echo "A system dialog will appear — click Install, wait, then run this again."
  xcode-select --install 2>/dev/null
  exit 1
fi

# ----------------------------------------------------------------------------
# 2. Fresh bundle skeleton.
# ----------------------------------------------------------------------------
echo "Assembling app bundle..."
rm -rf "$APP"
mkdir -p "$MACOS" "$RES"

# ----------------------------------------------------------------------------
# 3. Compile a self-contained release binary (no recompile on future launches).
# ----------------------------------------------------------------------------
echo "Compiling $APP_NAME.swift (release, this can take a moment)..."
if ! xcrun swiftc -Onone -parse-as-library "$SRC" -o "$BIN" 2>"$DIR/build.log"; then
  echo "Build failed. Details:"
  cat "$DIR/build.log"
  echo
  echo "Copy the errors above and send them to Claude — it'll patch BuildBuddy.swift."
  exit 1
fi
# Warnings are fine; only a non-zero exit above is fatal. Clean up the log on success.
rm -f "$DIR/build.log"

# ----------------------------------------------------------------------------
# 4. Info.plist — proper app identity, macOS 13 target.
# ----------------------------------------------------------------------------
cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIconFile</key><string>$APP_NAME</string>
  <key>CFBundleVersion</key><string>$BUILD_VERSION</string>
  <key>CFBundleShortVersionString</key><string>$SHORT_VERSION</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
echo -n 'APPL' > "$CONTENTS/PkgInfo"

# ----------------------------------------------------------------------------
# 5. App icon. Generate a simple .icns on the fly (no external art needed).
#    Uses only system tools: sips / iconutil, with a Python-drawn PNG source.
# ----------------------------------------------------------------------------
echo "Generating app icon..."
ICONSET="$DIR/.$APP_NAME.iconset"
BASEPNG="$DIR/.$APP_NAME-1024.png"
rm -rf "$ICONSET" "$BASEPNG"
mkdir -p "$ICONSET"

/usr/bin/python3 - "$BASEPNG" <<'PY' 2>/dev/null || SKIP_ICON=1
import sys
# Draw a 1024x1024 rounded-rect icon with a hammer/wrench-ish "build" glyph,
# using only the stdlib (no PIL). We emit a minimal PPM then convert via sips.
# To stay dependency-free we instead write a PNG using a tiny pure-python encoder.
import struct, zlib

W = H = 1024
def px(r,g,b,a=255): return bytes((r,g,b,a))

# Background gradient (indigo -> slate) with rounded corners.
def rounded(x, y, w, h, rad):
    # returns True if (x,y) inside rounded rect
    if x < rad and y < rad:
        return (rad-x)**2 + (rad-y)**2 <= rad*rad
    if x > w-rad and y < rad:
        return (x-(w-rad))**2 + (rad-y)**2 <= rad*rad
    if x < rad and y > h-rad:
        return (rad-x)**2 + (y-(h-rad))**2 <= rad*rad
    if x > w-rad and y > h-rad:
        return (x-(w-rad))**2 + (y-(h-rad))**2 <= rad*rad
    return True

rad = 180
rows = []
for y in range(H):
    t = y / (H-1)
    # gradient endpoints
    r = int(79 + (30-79)*t)
    g = int(70 + (41-70)*t)
    b = int(229 + (59-229)*t)
    row = bytearray()
    for x in range(W):
        if not rounded(x, y, W, H, rad):
            row += px(0,0,0,0)
            continue
        cr, cg, cb = r, g, b
        # centered filled circle "chip"
        dx, dy = x-512, y-512
        d2 = dx*dx + dy*dy
        if d2 <= 300*300:
            cr, cg, cb = 255, 255, 255
        if 210*210 <= d2 <= 250*250:
            cr, cg, cb = r, g, b
        # inner dot
        if d2 <= 120*120:
            cr, cg, cb = r, g, b
        row += px(cr, cg, cb, 255)
    rows.append(bytes(row))

def png(width, height, rows):
    raw = b''.join(b'\x00'+r for r in rows)
    def chunk(typ, data):
        c = typ + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)
    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    idat = zlib.compress(raw, 9)
    return sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b'')

open(sys.argv[1], 'wb').write(png(W, H, rows))
PY

if [ "${SKIP_ICON:-0}" = "0" ] && [ -f "$BASEPNG" ]; then
  for s in 16 32 128 256 512; do
    sips -z $s $s        "$BASEPNG" --out "$ICONSET/icon_${s}x${s}.png"      >/dev/null 2>&1
    sips -z $((s*2)) $((s*2)) "$BASEPNG" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null 2>&1
  done
  if iconutil -c icns "$ICONSET" -o "$RES/$APP_NAME.icns" >/dev/null 2>&1; then
    echo "Icon embedded."
  else
    echo "Icon conversion skipped (iconutil unavailable) — app still works."
  fi
  rm -rf "$ICONSET" "$BASEPNG"
else
  echo "Icon generation skipped — app still works, just uses the generic icon."
fi

# ----------------------------------------------------------------------------
# 6. Ad-hoc code sign. Gives the app a STABLE identity so macOS remembers any
#    permissions you grant it (Full Disk Access, etc.) across rebuilds.
#    Not sandboxed — full capabilities preserved.
# ----------------------------------------------------------------------------
echo "Signing (ad-hoc)..."
codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP" >/dev/null 2>&1 \
  && echo "Signed." \
  || echo "Signing skipped (codesign unavailable) — app still works."

# Locally built: no quarantine, but strip defensively.
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

echo
echo "Built: $APP"

# ----------------------------------------------------------------------------
# 7. Offer to install into /Applications.
# ----------------------------------------------------------------------------
printf "Install to /Applications now? [y/N] "
read -r ANSWER
case "$ANSWER" in
  y|Y|yes|YES)
    DEST="/Applications/$APP_NAME.app"
    if [ -d "$DEST" ]; then
      echo "Replacing existing $DEST..."
      rm -rf "$DEST"
    fi
    if cp -R "$APP" "$DEST" 2>/dev/null; then
      xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true
      echo "Installed to $DEST"
      echo "Opening..."
      open "$DEST"
    else
      echo "Couldn't copy to /Applications (permissions?)."
      echo "Drag $APP_NAME.app there manually — it's built and ready."
      open -R "$APP"
    fi
    ;;
  *)
    echo "Left the app here. Drag $APP_NAME.app to /Applications whenever you like."
    open -R "$APP"
    ;;
esac

echo "Done."

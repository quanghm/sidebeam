#!/bin/bash
set -euo pipefail

VERSION="${1:-0.0.1}"
APP_DIR="$(pwd)/.build/SideBeam.app"

echo "Building SideBeam v${VERSION}..."

# Try universal binary (needs full Xcode), fall back to native arch
if swift build -c release --arch arm64 --arch x86_64 2>/dev/null; then
    BINARY="$(pwd)/.build/apple/Products/Release/SideBeam"
else
    echo "Universal build unavailable, building native arch only..."
    swift build -c release
    BINARY="$(pwd)/.build/release/SideBeam"
fi

# Create .app bundle
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "$BINARY" "$APP_DIR/Contents/MacOS/"

# Copy and stamp Info.plist with version
sed "s/VERSION/${VERSION}/g" Sources/BeamerViewer/Info.plist > "$APP_DIR/Contents/Info.plist"

# Create PkgInfo
echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"

# Copy icon if available
if [ -f AppIcon.icns ]; then
    cp AppIcon.icns "$APP_DIR/Contents/Resources/"
elif command -v rsvg-convert &>/dev/null && [ -f icon-dark.svg ]; then
    ICONSET="$(pwd)/.build/SideBeam.iconset"
    mkdir -p "$ICONSET"
    for size in 16 32 128 256 512; do
        rsvg-convert -w "$size" -h "$size" icon-dark.svg -o "$ICONSET/icon_${size}x${size}.png"
        rsvg-convert -w "$((size*2))" -h "$((size*2))" icon-dark.svg -o "$ICONSET/icon_${size}x${size}@2x.png"
    done
    iconutil -c icns "$ICONSET" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
    rm -rf "$ICONSET"
fi

# Ad-hoc code sign (required for macOS to launch the app)
codesign --force --deep -s - "$APP_DIR"

echo "Built: $APP_DIR"
echo "Version: $VERSION"
file "$APP_DIR/Contents/MacOS/SideBeam"

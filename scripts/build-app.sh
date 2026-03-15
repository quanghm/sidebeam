#!/bin/bash
set -euo pipefail

VERSION="${1:-0.0.1}"
BUILD_DIR="$(pwd)/.build/release"
APP_DIR="$(pwd)/.build/BeamerViewer.app"

echo "Building Beamer Viewer v${VERSION}..."

# Build release binary
swift build -c release

# Create .app bundle
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/BeamerViewer" "$APP_DIR/Contents/MacOS/"

# Copy and stamp Info.plist with version
sed "s/VERSION/${VERSION}/g" Sources/BeamerViewer/Info.plist > "$APP_DIR/Contents/Info.plist"

# Create PkgInfo
echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"

echo "Built: $APP_DIR"
echo "Version: $VERSION"

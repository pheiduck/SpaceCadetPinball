#!/usr/bin/env bash

set -xe

brew_prefix="/usr/local"

# === Install dependencies via Homebrew ===
brew install cmake sdl2 sdl2_mixer

# === Build for x86_64 only ===
mkdir -p build_x86_64
pushd build_x86_64
cmake -DCMAKE_OSX_ARCHITECTURES=x86_64 \
      -DCMAKE_OSX_FRAMEWORK_PATH="$brew_prefix/Frameworks" \
      -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=../bin/x86_64 ..
cmake --build .
popd

# === Symlink frameworks (if not already present) ===
mkdir -p /opt/homebrew/Frameworks
ln -sf "$brew_prefix/Cellar/sdl2/2.32.10" /opt/homebrew/Frameworks/SDL2.framework
ln -sf "$brew_prefix/Cellar/sdl2_mixer/2.8.1_1" /opt/homebrew/Frameworks/SDL2_mixer.framework

# === Prepare .app Bundle ===
sw_version='2.2.7'
APP_DIR="SpaceCadetPinball.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$APP_DIR/Contents/Frameworks"

# Copy app resources
cp -a Platform/macOS/Info.plist "$APP_DIR/Contents/"
cp -a Platform/macOS/SpaceCadetPinball.icns "$APP_DIR/Contents/Resources/"

# Copy Homebrew-installed frameworks
cp -a /opt/homebrew/Frameworks/SDL2.framework "$APP_DIR/Contents/Frameworks/"
cp -a /opt/homebrew/Frameworks/SDL2_mixer.framework "$APP_DIR/Contents/Frameworks/"

# Copy x86_64 executable
cp -a bin/x86_64/SpaceCadetPinball "$APP_DIR/Contents/MacOS/"

# Copy game assets
cp -a PinballAssets/* "$APP_DIR/Contents/Resources/"
rm -rf PinballAssets

# Update version and PkgInfo
sed -i '' "s/CHANGEME_SW_VERSION/$sw_version/" "$APP_DIR/Contents/Info.plist"
echo -n "APPLE" > "$APP_DIR/Contents/PkgInfo"

# === Ad-hoc code signing ===
codesign --force --deep --sign - "$APP_DIR"

# === Create DMG ===
hdiutil create -fs HFS+ -srcfolder "$APP_DIR" \
  -volname "SpaceCadetPinball $sw_version" \
  "SpaceCadetPinball-mac-$sw_version.dmg"

# === Clean up ===
rm -rf "$APP_DIR" build_x86_64 bin/x86_64

echo "✅ x86_64 build complete! DMG created: SpaceCadetPinball-mac-$sw_version.dmg"

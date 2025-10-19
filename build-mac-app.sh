#!/usr/bin/env bash

set -xe

# === Prerequisites: make sure Homebrew is installed ===
if ! command -v brew &>/dev/null; then
    echo "Homebrew not found! Please install Homebrew first: https://brew.sh/"
    exit 1
fi

# === Install dependencies via Homebrew ===
brew install cmake sdl2 sdl2_mixer

# === Build for arm64/x86_64 ===
mkdir -p build_universal
pushd build_universal
brew_prefix=$(brew --prefix)
cmake -S . -B build_universal \
      -DCMAKE_PREFIX_PATH="$(brew --prefix)" \
      -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
      -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=$(pwd)/bin
cmake --build build_universal --config Release
popd

# === Create universal binary ===
mkdir -p bin
lipo -create bin/x86_64/SpaceCadetPinball bin/arm64/SpaceCadetPinball -output bin/SpaceCadetPinball

# === Prepare .app Bundle ===
sw_version='2.2.7'
APP_DIR="SpaceCadetPinball.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$APP_DIR/Contents/Frameworks"

# Copy app resources
cp -a Platform/macOS/Info.plist "$APP_DIR/Contents/"
cp -a Platform/macOS/SpaceCadetPinball.icns "$APP_DIR/Contents/Resources/"

# Copy Homebrew-installed frameworks
cp -a "$SDL2_FRAMEWORK" "$APP_DIR/Contents/Frameworks/"
cp -a "$SDL2_MIXER_FRAMEWORK" "$APP_DIR/Contents/Frameworks/"

# Copy universal executable
cp -a bin/SpaceCadetPinball "$APP_DIR/Contents/MacOS/"

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
rm -rf "$APP_DIR" build_x86_64 build_arm64 bin/x86_64 bin/arm64

echo "✅ Universal build complete! DMG created: SpaceCadetPinball-mac-$sw_version.dmg"

#!/usr/bin/env bash

set -xe

# === Prerequisites: make sure Homebrew is installed ===
if ! command -v brew &>/dev/null; then
    echo "Homebrew not found! Please install Homebrew first: https://brew.sh/"
    exit 1
fi

# === Install dependencies via Homebrew ===
brew install cmake sdl2 sdl2_mixer lipo

# Get Homebrew framework paths
brew_prefix=$(brew --prefix)
SDL2_FRAMEWORK="$brew_prefix/Frameworks/SDL2.framework"
SDL2_MIXER_FRAMEWORK="$brew_prefix/Frameworks/SDL2_mixer.framework"

# Verify frameworks exist
if [ ! -d "$SDL2_FRAMEWORK" ] || [ ! -d "$SDL2_MIXER_FRAMEWORK" ]; then
    echo "SDL2 or SDL2_mixer framework not found in Homebrew path."
    exit 1
fi

# === Build for x86_64 ===
mkdir -p build_x86_64
pushd build_x86_64
cmake -DCMAKE_OSX_ARCHITECTURES=x86_64 \
      -DCMAKE_OSX_FRAMEWORK_PATH="$brew_prefix/Frameworks" \
      -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=../bin/x86_64 ..
cmake --build .
popd

# === Build for arm64 ===
mkdir -p build_arm64
pushd build_arm64
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DCMAKE_OSX_FRAMEWORK_PATH="$brew_prefix/Frameworks" \
      -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=../bin/arm64 ..
cmake --build .
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

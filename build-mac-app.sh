#!/usr/bin/env bash

set -xe

# === Make sure dependencies are installed via Homebrew ===
brew install cmake sdl2 sdl2_mixer

# === Build with CMake ===
cmake -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=bin \
      -DCMAKE_PREFIX_PATH="$(brew --prefix sdl2);$(brew --prefix sdl2_mixer)" \
      .
cmake --build .

# === Prepare .app Bundle ===
sw_version='2.1.9'

mkdir -p SpaceCadetPinball.app/Contents/MacOS
mkdir -p SpaceCadetPinball.app/Contents/Resources
mkdir -p SpaceCadetPinball.app/Contents/Frameworks

cp -a Platform/macOS/Info.plist SpaceCadetPinball.app/Contents/
cp -a Platform/macOS/SpaceCadetPinball.icns SpaceCadetPinball.app/Contents/Resources/
cp -a bin/SpaceCadetPinball SpaceCadetPinball.app/Contents/MacOS/

# Optional: copy frameworks into the app bundle if you want a self-contained app
# These paths may vary between Intel and Apple Silicon Macs
SDL2_FW="$(brew --prefix sdl2)/lib/SDL2.framework"
SDL2_MIXER_FW="$(brew --prefix sdl2_mixer)/lib/SDL2_mixer.framework"

if [ -d "$SDL2_FW" ]; then
  cp -a "$SDL2_FW" SpaceCadetPinball.app/Contents/Frameworks/
fi

if [ -d "$SDL2_MIXER_FW" ]; then
  cp -a "$SDL2_MIXER_FW" SpaceCadetPinball.app/Contents/Frameworks/
fi

# === Add game assets ===
curl -LO https://archive.org/download/winXP-pinball/Win32.Pinball.zip
unzip -o Win32.Pinball.zip -d PinballAssets/

# Copy contents of Pinball folder into Resources
cp -a PinballAssets/Pinball/* SpaceCadetPinball.app/Contents/Resources/

rm -rf Win32.Pinball.zip PinballAssets/

# === Finalize bundle ===
sed -i '' "s/CHANGEME_SW_VERSION/$sw_version/" SpaceCadetPinball.app/Contents/Info.plist
echo -n "APPLE" > SpaceCadetPinball.app/Contents/PkgInfo

# === Ad-hoc code signing ===
codesign --force --deep --sign - SpaceCadetPinball.app

# === Create DMG ===
hdiutil create -fs HFS+ -srcfolder SpaceCadetPinball.app \
  -volname "SpaceCadetPinball $sw_version" \
  "SpaceCadetPinball-$sw_version-mac.dmg"

# === Clean up ===
rm -rf SpaceCadetPinball.app

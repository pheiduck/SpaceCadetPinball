#!/usr/bin/env bash

set -xe

# === Prepare directories ===
mkdir -p Libs
cd Libs

# === SDL3 ===
sdl_version='3.2.18'
sdl_filename="SDL3-$sdl_version.dmg"
sdl_url="https://github.com/libsdl-org/SDL/releases/download/release-$sdl_version/$sdl_filename"

if [ ! -f "$sdl_filename" ]; then
  curl -sSf -L -O "$sdl_url"
fi

echo "137029b3b4d76df95350bb1d5336d5a593e4e1eaf9faf413abee09da6c5ec037  $sdl_filename" | shasum -a 256 -c

hdiutil attach "$sdl_filename" -quiet
cp -a /Volumes/SDL3/SDL3.framework .
hdiutil detach /Volumes/SDL3

# === SDL2_mixer ===
sdl_mixer_version='2.8.1'
sdl_mixer_filename="SDL2_mixer-$sdl_mixer_version.dmg"
sdl_mixer_url="https://github.com/libsdl-org/SDL_mixer/releases/download/release-$sdl_mixer_version/$sdl_mixer_filename"

if [ ! -f "$sdl_mixer_filename" ]; then
  curl -sSf -L -O "$sdl_mixer_url"
fi

echo "d74052391ee4d91836bf1072a060f1d821710f3498a54996c66b9a17c79a72d1  $sdl_mixer_filename" | shasum -a 256 -c

hdiutil attach "$sdl_mixer_filename" -quiet
cp -a /Volumes/SDL2_mixer/SDL2_mixer.framework .
hdiutil detach /Volumes/SDL2_mixer

cd ..

# === Build with CMake ===
cmake -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=bin .
cmake --build .

# === Prepare .app Bundle ===
sw_version='2.1.9'

mkdir -p SpaceCadetPinball.app/Contents/MacOS
mkdir -p SpaceCadetPinball.app/Contents/Resources
mkdir -p SpaceCadetPinball.app/Contents/Frameworks

cp -a Platform/macOS/Info.plist SpaceCadetPinball.app/Contents/
cp -a Platform/macOS/SpaceCadetPinball.icns SpaceCadetPinball.app/Contents/Resources/
cp -a Libs/SDL3.framework SpaceCadetPinball.app/Contents/Frameworks/
cp -a Libs/SDL2_mixer.framework SpaceCadetPinball.app/Contents/Frameworks/
cp -a bin/SpaceCadetPinball SpaceCadetPinball.app/Contents/MacOS/

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

#!/bin/bash

# Create DMG installer for Local JSON Reader
echo "Creating DMG installer..."

# Build release version
swift build --configuration release

# Update app bundle
sudo cp .build/release/JsonReader JsonReader.app/Contents/MacOS/JsonReader

# Create temporary directory for DMG contents
mkdir -p dmg_contents
cp -r JsonReader.app dmg_contents/

# Create Applications symlink
ln -s /Applications dmg_contents/Applications

# Create DMG
hdiutil create -volname "Local JSON Reader" -srcfolder dmg_contents -ov -format UDZO Local_JSON_Reader.dmg

# Clean up
rm -rf dmg_contents

echo "DMG created: Local_JSON_Reader.dmg"
echo "Double-click the DMG to mount it, then drag the app to Applications."
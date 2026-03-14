#!/bin/bash

# Local JSON Reader Installer for macOS
echo "Local JSON Reader Installer"
echo "=========================="

# Build release version
echo "Building release version..."
swift build --configuration release

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Update app bundle
echo "Updating app bundle..."
sudo cp .build/release/JsonReader JsonReader.app/Contents/MacOS/JsonReader

if [ $? -ne 0 ]; then
    echo "Failed to update app bundle!"
    exit 1
fi

# Install to Applications folder
echo "Installing to Applications folder..."
sudo cp -r JsonReader.app /Applications/

if [ $? -ne 0 ]; then
    echo "Failed to install to Applications!"
    exit 1
fi

echo "Installation complete!"
echo "You can now find 'Local JSON Reader' in your Applications folder."
echo ""
echo "To launch: Open Finder → Applications → Local JSON Reader"
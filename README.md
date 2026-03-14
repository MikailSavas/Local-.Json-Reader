# Local JSON Reader

A native MacOS desktop application to read and display local JSON files with a beautiful, modern interface built with SwiftUI.

## Installation

### Option 1: Automated Installer (Recommended)
1. Open Terminal in the project folder
2. Run: `./install.sh`
3. Enter your password when prompted
4. The app will be installed to your Applications folder

### Option 2: Manual Installation
1. Open Terminal in the project folder
2. Build the release version:
   ```bash
   swift build --configuration release
   ```
3. Update the app bundle:
   ```bash
   sudo cp .build/release/JsonReader JsonReader.app/Contents/MacOS/JsonReader
   ```
4. Install to Applications:
   ```bash
   sudo cp -r JsonReader.app /Applications/
   ```
5. Find "Local JSON Reader" in your Applications folder

### Option 3: DMG Installer (Professional)
1. Open Terminal in the project folder
2. Run: `./create_dmg.sh`
3. Enter your password when prompted
4. Double-click the created `Local_JSON_Reader.dmg` file
5. Drag "Local JSON Reader" to your Applications folder

### Option 4: Using the PKG Installer
1. Double-click `JsonReader.pkg` in the project folder
2. Follow the installation wizard
3. The app will be installed to your Applications folder

## Features

- **Native MacOS Interface**: Built with SwiftUI for a polished, native Mac experience
- **Custom App Icon**: Professional icon designed for the application
- **File Selection**: Easy file picker to select JSON files from your filesystem
- **Hierarchical Display**: JSON structures shown in expandable disclosure groups
- **Type Indicators**: Each value shows its data type (string, number, boolean, object, array)
- **Syntax Highlighting**: Values colored by type for better readability
- **Search & Highlight**: Real-time search functionality that highlights matching text in keys and values
- **Smart Auto-Expand**: Search automatically expands sections containing matches
- **Sidebar Navigation**: Compact sidebar showing JSON structure with item counts
- **Interactive Selection**: Click sidebar items to highlight them in the main view
- **Error Handling**: Clear error messages for invalid JSON or loading issues
- **Responsive Design**: Clean, modern UI that adapts to content
- **Rich Text Editor**: Multiple view modes (Tree, Search, Editor)
- **Markdown Support**: Automatic rendering of markdown content in JSON strings
- **Advanced Sorting**: A-Z, Z-A sorting options for JSON objects
- **Text Editor Mode**: Full JSON editing with syntax highlighting and formatting

## Requirements

## Requirements

- macOS 12.0 or later
- Swift 5.7 or later (comes pre-installed on recent macOS versions)

## Installation

### Option 1: Using the Installer Package (Recommended)

1. Download or build the `JsonReader.pkg` file
2. Double-click `JsonReader.pkg` to start the installation
3. Follow the standard MacOS installer prompts
4. The app will be installed to your Applications folder

### Option 2: Manual Build

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/local-json-reader.git
   cd local-json-reader
   ```

2. Build the application:
   ```bash
   swift build
   ```

3. Create the app bundle (optional):
   ```bash
   mkdir -p JsonReader.app/Contents/MacOS JsonReader.app/Contents/Resources
   cp .build/debug/JsonReader JsonReader.app/Contents/MacOS/
   cp Info.plist JsonReader.app/Contents/
   ```

4. Copy `JsonReader.app` to your Applications folder

## Usage

Run the application:
Easily open from your applications folder

OR 

```bash
swift run
```

Or run the built executable directly:
```bash
.build/debug/JsonReader
```

### How to Use

1. Click the "Open JSON File" button (with document icon)
2. Select a `.json` file from your Mac
3. The JSON structure will be displayed in a hierarchical, expandable view
4. Use the **sidebar** on the left to navigate the JSON structure quickly
5. Click any item in the sidebar to highlight it in the main view
6. Use the search field to find specific keys or values - matches will be highlighted in yellow
7. Search automatically expands sections containing matches for easy navigation
8. Click disclosure triangles to expand/collapse objects and arrays
9. Values are color-coded: green for strings, blue for numbers, orange for booleans
10. Use the "Clear" button to remove the current JSON and load a new one

## Creating an App Bundle (Optional)

For a proper Mac app installation:

1. Open the project in Xcode:
   ```bash
   open Package.swift
   ```
   (This will open Xcode with the Swift Package)

2. In Xcode, go to Product > Build

3. Find the built app in `~/Library/Developer/Xcode/DerivedData/.../Build/Products/Debug/JsonReader.app`

4. Copy `JsonReader.app` to your Applications folder for system-wide installation

## Sample JSON

A sample `test.json` file is included for testing the application. 

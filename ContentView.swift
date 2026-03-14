import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var jsonData: Any? = nil
    @State private var showingFilePicker = false
    @State private var errorMessage: String? = nil
    @State private var showingError = false
    @State private var searchQuery = ""
    @State private var expandedPaths = Set<String>()
    @State private var selectedPath: String? = nil
    @State private var matchingPaths = Set<String>()
    @State private var viewMode: ViewMode = .tree
    
    enum ViewMode {
        case tree, searchResults
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            HStack {
                Button(action: {
                    showingFilePicker = true
                }) {
                    Label("Open JSON File", systemImage: "doc.badge.plus")
                        .font(.headline)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                Picker("View", selection: $viewMode) {
                            Text("Tree").tag(ViewMode.tree)
                            Text("Search Results").tag(ViewMode.searchResults)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                        
                        
                Spacer()
                
                if jsonData != nil {
                    HStack(spacing: 12) {
                        TextField("Search JSON...", text: $searchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                        
                        Button(action: {
                            jsonData = nil
                            searchQuery = ""
                            expandedPaths.removeAll()
                            selectedPath = nil
                        }) {
                            Label("Clear", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))
            
            // Main content
            if let data = jsonData {
                HSplitView {
                    // Sidebar
                    VStack(alignment: .leading) {
                        Text("JSON Structure")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ScrollView {
                            SidebarView(
                                data: data,
                                searchQuery: searchQuery,
                                expandedPaths: $expandedPaths,
                                selectedPath: $selectedPath,
                                matchingPaths: matchingPaths
                            )
                            .padding(.horizontal)
                        }
                    }
                    .frame(minWidth: 250, maxWidth: 400)
                    .background(Color(.controlBackgroundColor))
                    
                    // Main content area
                    VStack(alignment: .leading) {
                        if let selectedPath = selectedPath {
                            Text("Selected: \(selectedPath)")
                                .font(.subheadline)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        
                        ScrollView {
                            if viewMode == .tree {
                                JsonView(
                                    data: data,
                                    searchQuery: searchQuery,
                                    expandedPaths: $expandedPaths,
                                    selectedPath: $selectedPath,
                                    matchingPaths: matchingPaths
                                )
                                .padding(.horizontal)
                            } else {
                                SearchResultsView(
                                    data: data,
                                    searchQuery: searchQuery,
                                    selectedPath: $selectedPath
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No JSON file loaded")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Click 'Open JSON File' to get started")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.json]
        ) { result in
            switch result {
            case .success(let url):
                loadJson(from: url)
            case .failure(let error):
                errorMessage = "Failed to select file: \(error.localizedDescription)"
                showingError = true
            }
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: searchQuery) { newValue in
            updateExpansionForSearch()
        }
    }
    
    private func loadJson(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            jsonData = try JSONSerialization.jsonObject(with: data)
            errorMessage = nil
            expandedPaths.removeAll()
            selectedPath = nil
            searchQuery = ""
            matchingPaths.removeAll()
        } catch let decodingError as DecodingError {
            errorMessage = "Invalid JSON format: \(decodingError.localizedDescription)"
            showingError = true
        } catch {
            errorMessage = "Failed to load JSON: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func updateExpansionForSearch() {
        guard let data = jsonData, !searchQuery.isEmpty else {
            if searchQuery.isEmpty {
                expandedPaths.removeAll()
                matchingPaths.removeAll()
            }
            return
        }
        
        var pathsToExpand = Set<String>()
        var pathsWithMatches = Set<String>()
        findMatchingPaths(in: data, currentPath: "", pathsToExpand: &pathsToExpand, pathsWithMatches: &pathsWithMatches)
        expandedPaths = pathsToExpand
        matchingPaths = pathsWithMatches
    }
    
    private func findMatchingPaths(in data: Any, currentPath: String, pathsToExpand: inout Set<String>, pathsWithMatches: inout Set<String>) {
        var hasMatchInThisSection = false
        
        if let dict = data as? [String: Any] {
            for (key, value) in dict {
                let keyPath = currentPath.isEmpty ? key : "\(currentPath).\(key)"
                
                // Check if key matches search
                if key.lowercased().contains(searchQuery.lowercased()) {
                    hasMatchInThisSection = true
                    // Expand all parent paths
                    let pathComponents = keyPath.split(separator: ".")
                    for i in 0..<pathComponents.count {
                        let partialPath = pathComponents[0...i].joined(separator: ".")
                        pathsToExpand.insert(partialPath)
                        pathsWithMatches.insert(partialPath)
                    }
                }
                
                // Check if string value matches search
                if let stringValue = value as? String,
                   stringValue.lowercased().contains(searchQuery.lowercased()) {
                    hasMatchInThisSection = true
                    // Expand all parent paths
                    let pathComponents = keyPath.split(separator: ".")
                    for i in 0..<pathComponents.count {
                        let partialPath = pathComponents[0...i].joined(separator: ".")
                        pathsToExpand.insert(partialPath)
                        pathsWithMatches.insert(partialPath)
                    }
                }
                
                _ = findMatchingPaths(in: value, currentPath: keyPath, pathsToExpand: &pathsToExpand, pathsWithMatches: &pathsWithMatches)
                
                // If child has match, mark this section
                if pathsWithMatches.contains(keyPath) {
                    hasMatchInThisSection = true
                }
            }
        } else if let array = data as? [Any] {
            for (index, value) in array.enumerated() {
                let itemPath = currentPath.isEmpty ? "[\(index)]" : "\(currentPath)[\(index)]"
                
                // Check if array item value matches search
                if let stringValue = value as? String,
                   stringValue.lowercased().contains(searchQuery.lowercased()) {
                    hasMatchInThisSection = true
                    // Expand all parent paths
                    let pathComponents = currentPath.split(separator: ".")
                    for i in 0..<pathComponents.count {
                        let partialPath = pathComponents[0...i].joined(separator: ".")
                        pathsToExpand.insert(partialPath)
                        pathsWithMatches.insert(partialPath)
                    }
                    pathsToExpand.insert(currentPath)
                    pathsWithMatches.insert(currentPath)
                }
                
                // Recursively check nested structures
                _ = findMatchingPaths(in: value, currentPath: itemPath, pathsToExpand: &pathsToExpand, pathsWithMatches: &pathsWithMatches)
                
                // If child has match, mark this section
                if pathsWithMatches.contains(itemPath) {
                    hasMatchInThisSection = true
                }
            }
        }
        
        // If this section has matches, add it to matching paths
        if hasMatchInThisSection && !currentPath.isEmpty {
            pathsWithMatches.insert(currentPath)
        }
    }
}

struct SidebarView: View {
    let data: Any
    let searchQuery: String
    @Binding var expandedPaths: Set<String>
    @Binding var selectedPath: String?
    let matchingPaths: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SidebarItem(
                data: data,
                path: "",
                matchingPaths: matchingPaths,
                searchQuery: searchQuery,
                expandedPaths: $expandedPaths,
                selectedPath: $selectedPath
            )
        }
    }
}

struct SidebarItem: View {
    let data: Any
    let path: String
    let matchingPaths: Set<String>
    let searchQuery: String
    @Binding var expandedPaths: Set<String>
    @Binding var selectedPath: String?
    
    var body: some View {
        Group {
            if let dict = data as? [String: Any] {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedPaths.contains(path) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedPaths.insert(path)
                            } else {
                                expandedPaths.remove(path)
                            }
                        }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(dict.keys.sorted(), id: \.self) { key in
                            let itemPath = path.isEmpty ? key : "\(path).\(key)"
                            SidebarItem(
                                data: dict[key]!,
                                path: itemPath,
                                matchingPaths: matchingPaths,
                                searchQuery: searchQuery,
                                expandedPaths: $expandedPaths,
                                selectedPath: $selectedPath
                            )
                        }
                    }
                    .padding(.leading, 8)
                } label: {
                    HStack {
                        Image(systemName: "curlybraces")
                            .foregroundColor(.blue)
                        HighlightedText(text: path.isEmpty ? "Root Object" : path.components(separatedBy: ".").last!, searchQuery: searchQuery)
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(dict.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .background(sidebarBackground(for: path))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPath = path
                    }
                    .background(selectedPath == path ? Color.blue.opacity(0.1) : Color.clear)
                }
            } else if let array = data as? [Any] {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedPaths.contains(path) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedPaths.insert(path)
                            } else {
                                expandedPaths.remove(path)
                            }
                        }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(array.indices, id: \.self) { index in
                            let itemPath = path.isEmpty ? "[\(index)]" : "\(path)[\(index)]"
                            SidebarItem(
                                data: array[index],
                                path: itemPath,
                                matchingPaths: matchingPaths,
                                searchQuery: searchQuery,
                                expandedPaths: $expandedPaths,
                                selectedPath: $selectedPath
                            )
                        }
                    }
                    .padding(.leading, 8)
                } label: {
                    HStack {
                        Image(systemName: "square.fill")
                            .foregroundColor(.orange)
                        Text(path.isEmpty ? "Root Array" : "[\(path.components(separatedBy: "[").last?.replacingOccurrences(of: "]", with: "") ?? "0")]")
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(array.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .background(sidebarBackground(for: path))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPath = path
                    }
                    .background(selectedPath == path ? Color.blue.opacity(0.1) : Color.clear)
                }
            } else {
                HStack {
                    Image(systemName: valueIcon(for: data))
                        .foregroundColor(valueColor(for: data))
                    HighlightedText(text: path.isEmpty ? "Root Value" : path.components(separatedBy: ".").last!, searchQuery: searchQuery)
                        .font(.system(size: 12))
                    Spacer()
                    Text(typeDescription(for: data))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .background(sidebarBackground(for: path))
                .padding(.vertical, 2)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedPath = path
                }
                .background(selectedPath == path ? Color.blue.opacity(0.1) : Color.clear)
            }
        }
    }
    
    private func valueIcon(for data: Any) -> String {
        if data is String { return "text.quote" }
        if data is Int || data is Double { return "number" }
        if data is Bool { return "checkmark.square" }
        return "circle"
    }
    
    private func valueColor(for data: Any) -> Color {
        if data is String { return .green }
        if data is Int || data is Double { return .blue }
        if data is Bool { return .orange }
        return .gray
    }
    
    private func typeDescription(for value: Any?) -> String {
        guard let value = value else { return "null" }
        switch value {
        case is String: return "string"
        case is Int, is Double: return "number"
        case is Bool: return "boolean"
        case is [String: Any]: return "object"
        case is [Any]: return "array"
        default: return "unknown"
        }
    }
    
    private func sidebarBackground(for path: String) -> Color {
        if selectedPath == path {
            return Color.blue.opacity(0.2)
        } else if matchingPaths.contains(path) {
            return Color.yellow.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

struct JsonView: View {
    let data: Any
    let searchQuery: String
    @Binding var expandedPaths: Set<String>
    @Binding var selectedPath: String?
    let matchingPaths: Set<String>
    
    var body: some View {
        Group {
            if let dict = data as? [String: Any] {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(dict.keys.sorted(), id: \.self) { key in
                        let itemPath = key
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedPaths.contains(itemPath) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedPaths.insert(itemPath)
                                    } else {
                                        expandedPaths.remove(itemPath)
                                    }
                                }
                            )
                        ) {
                            JsonView(
                                data: dict[key]!,
                                searchQuery: searchQuery,
                                expandedPaths: $expandedPaths,
                                selectedPath: $selectedPath,
                                matchingPaths: matchingPaths
                            )
                            .padding(.leading)
                        } label: {
                            HStack {
                                HighlightedText(text: "\"\(key)\"", searchQuery: searchQuery)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.blue)
                                Text(":")
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                                Text(typeDescription(for: dict[key]))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(sectionBackground(for: itemPath))
                            .cornerRadius(4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPath = itemPath
                            }
                        }
                    }
                }
            } else if let array = data as? [Any] {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(array.indices, id: \.self) { index in
                        let itemPath = "[\(index)]"
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedPaths.contains(itemPath) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedPaths.insert(itemPath)
                                    } else {
                                        expandedPaths.remove(itemPath)
                                    }
                                }
                            )
                        ) {
                            JsonView(
                                data: array[index],
                                searchQuery: searchQuery,
                                expandedPaths: $expandedPaths,
                                selectedPath: $selectedPath,
                                matchingPaths: matchingPaths
                            )
                            .padding(.leading)
                        } label: {
                            HStack {
                                Text("[\(index)]")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.purple)
                                    .fontWeight(.medium)
                                Text(":")
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                                Text(typeDescription(for: array[index]))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(sectionBackground(for: itemPath))
                            .cornerRadius(4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPath = itemPath
                            }
                        }
                    }
                }
            } else {
                JsonValueDisplay(value: data, searchQuery: searchQuery)
            }
        }
    }
    
    private func typeDescription(for value: Any?) -> String {
        guard let value = value else { return "null" }
        switch value {
        case is String: return "string"
        case is Int, is Double: return "number"
        case is Bool: return "boolean"
        case is [String: Any]: return "object"
        case is [Any]: return "array"
        default: return "unknown"
        }
    }
    
    private func sectionBackground(for path: String) -> Color {
        if selectedPath == path {
            return Color.blue.opacity(0.2)
        } else if matchingPaths.contains(path) {
            return Color.yellow.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private func stringRepresentation(of data: Any) -> String {
        if let string = data as? String {
            return "\"\(string)\""
        } else if let number = data as? NSNumber {
            return "\(number)"
        } else if let bool = data as? Bool {
            return "\(bool)"
        } else {
            return "\(data)"
        }
    }
}

struct SearchResultsView: View {
    let data: Any
    let searchQuery: String
    @Binding var selectedPath: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if searchQuery.isEmpty {
                Text("Enter a search query to see results")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                let results = findSearchResults(in: data, currentPath: "")
                if results.isEmpty {
                    Text("No matches found for '\(searchQuery)'")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Text("\(results.count) matches found")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(results, id: \.path) { result in
                        SearchResultRow(result: result, selectedPath: $selectedPath)
                    }
                }
            }
        }
    }
    
    private func findSearchResults(in data: Any, currentPath: String) -> [SearchResult] {
        var results: [SearchResult] = []
        
        if let dict = data as? [String: Any] {
            for (key, value) in dict {
                let keyPath = currentPath.isEmpty ? key : "\(currentPath).\(key)"
                
                // Check if key matches
                if key.lowercased().contains(searchQuery.lowercased()) {
                    results.append(SearchResult(
                        path: keyPath,
                        key: key,
                        value: value,
                        matchType: .key
                    ))
                }
                
                // Check if string value matches
                if let stringValue = value as? String,
                   stringValue.lowercased().contains(searchQuery.lowercased()) {
                    results.append(SearchResult(
                        path: keyPath,
                        key: key,
                        value: stringValue,
                        matchType: .value
                    ))
                }
                
                // Recursively search nested structures
                results.append(contentsOf: findSearchResults(in: value, currentPath: keyPath))
            }
        } else if let array = data as? [Any] {
            for (index, value) in array.enumerated() {
                let itemPath = currentPath.isEmpty ? "[\(index)]" : "\(currentPath)[\(index)]"
                
                // Check if array item value matches
                if let stringValue = value as? String,
                   stringValue.lowercased().contains(searchQuery.lowercased()) {
                    results.append(SearchResult(
                        path: itemPath,
                        key: "[\(index)]",
                        value: stringValue,
                        matchType: .value
                    ))
                }
                
                // Recursively search nested structures
                results.append(contentsOf: findSearchResults(in: value, currentPath: itemPath))
            }
        }
        
        return results
    }
}

struct SearchResult: Identifiable {
    let id = UUID()
    let path: String
    let key: String
    let value: Any
    let matchType: MatchType
    
    enum MatchType {
        case key, value
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    @Binding var selectedPath: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(result.matchType == .key ? "Key" : "Value")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(result.matchType == .key ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
            
            HStack(alignment: .top) {
                HighlightedText(text: result.key, searchQuery: "")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue)
                
                Text(":")
                    .foregroundColor(.secondary)
                
                JsonValueView(value: result.value, searchQuery: "")
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedPath = result.path
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selectedPath == result.path ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct JsonValueView: View {
    let value: Any
    let searchQuery: String
    
    var body: some View {
        Group {
            if let string = value as? String {
                HighlightedText(text: "\"\(string)\"", searchQuery: searchQuery)
                    .foregroundColor(.green)
            } else if let number = value as? NSNumber {
                HighlightedText(text: "\(number)", searchQuery: searchQuery)
                    .foregroundColor(.blue)
            } else if let bool = value as? Bool {
                HighlightedText(text: "\(bool)", searchQuery: searchQuery)
                    .foregroundColor(.orange)
            } else if value is [String: Any] {
                Text("{...}")
                    .foregroundColor(.purple)
            } else if value is [Any] {
                Text("[...]")
                    .foregroundColor(.purple)
            } else {
                HighlightedText(text: "\(value)", searchQuery: searchQuery)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct JsonValueDisplay: View {
    let value: Any
    let searchQuery: String
    
    var body: some View {
        Group {
            if let string = value as? String {
                HighlightedText(text: "\"\(string)\"", searchQuery: searchQuery)
                    .foregroundColor(.green)
            } else if let number = value as? NSNumber {
                HighlightedText(text: "\(number)", searchQuery: searchQuery)
                    .foregroundColor(.blue)
            } else if let bool = value as? Bool {
                HighlightedText(text: "\(bool)", searchQuery: searchQuery)
                    .foregroundColor(.orange)
            } else if value is NSNull {
                Text("null")
                    .foregroundColor(.gray)
            } else {
                HighlightedText(text: "\(value)", searchQuery: searchQuery)
                    .foregroundColor(.primary)
            }
        }
        .font(.system(.body, design: .monospaced))
    }
}

struct HighlightedText: View {
    let text: String
    let searchQuery: String
    
    var body: some View {
        if searchQuery.isEmpty {
            Text(text)
        } else {
            let lowerText = text.lowercased()
            let lowerQuery = searchQuery.lowercased()
            if lowerQuery.isEmpty || !lowerText.contains(lowerQuery) {
                Text(text)
            } else {
                // Create highlighted text using multiple Text views
                let components = highlightComponents()
                HStack(spacing: 0) {
                    ForEach(components.indices, id: \.self) { index in
                        Text(components[index].text)
                            .background(components[index].isHighlighted ? Color.yellow.opacity(0.3) : Color.clear)
                            .foregroundColor(components[index].isHighlighted ? .black : .primary)
                    }
                }
            }
        }
    }
    
    private func highlightComponents() -> [(text: String, isHighlighted: Bool)] {
        var components: [(String, Bool)] = []
        let lowerText = text.lowercased()
        let lowerQuery = searchQuery.lowercased()
        
        if lowerQuery.isEmpty || !lowerText.contains(lowerQuery) {
            return [(text, false)]
        }
        
        var searchRange = text.startIndex..<text.endIndex
        var currentIndex = text.startIndex
        
        while let range = text.range(of: searchQuery, options: .caseInsensitive, range: searchRange) {
            // Add text before the match
            if currentIndex < range.lowerBound {
                components.append((String(text[currentIndex..<range.lowerBound]), false))
            }
            // Add the highlighted match
            components.append((String(text[range]), true))
            currentIndex = range.upperBound
            searchRange = currentIndex..<text.endIndex
        }
        
        // Add remaining text
        if currentIndex < text.endIndex {
            components.append((String(text[currentIndex..<text.endIndex]), false))
        }
        
        return components
    }
}
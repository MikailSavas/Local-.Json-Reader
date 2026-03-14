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
                            JsonView(
                                data: data,
                                searchQuery: searchQuery,
                                expandedPaths: $expandedPaths,
                                selectedPath: $selectedPath,
                                matchingPaths: matchingPaths
                            )
                            .padding(.horizontal)
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
                searchQuery: searchQuery,
                expandedPaths: $expandedPaths,
                selectedPath: $selectedPath,
                matchingPaths: matchingPaths
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
                                searchQuery: searchQuery,
                                expandedPaths: $expandedPaths,
                                selectedPath: $selectedPath,
                                matchingPaths: matchingPaths
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
                    .sidebarBackground(for: path)
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
                            let itemPath
                                data: array[index],
                                path: itemPath,
                                searchQuery: searchQuery,
                                expandedPaths: $expandedPaths,
                                selectedPath: $selectedPath,
                                matchingPaths: matchingPathshs,
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
                            .fontgroundColor(.secondary)
                    }
                    .s(.caption)
                            .foreidebarBackground(for: path)
                    }
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
                 
                .s   Text(typeDescription(for: data))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }idebarBackground(for: path)
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
                                HighlightedText(text: key, searchQuery: searchQuery)
                                    .font(.system(.body, design: .default))
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
                                    .font(.system(.body, design: .default))
                                    .fontWeight(.medium)
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
                HighlightedText(text: stringRepresentation(of: data), searchQuery: searchQuery)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(valueColor(for: data))
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
    
    private func valueColor(for data: Any) -> Color {
        if data is String { return .green }
        if data is Int || data is Double { return .blue }
        if data is Bool { return .orange }
        return .primary
    }

            let lowerQuery = searchQuery.lowercased()
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
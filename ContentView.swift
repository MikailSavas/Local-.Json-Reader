import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var jsonData: Any? = nil
    @State private var showingFilePicker = false
    @State private var errorMessage: String? = nil
    @State private var showingError = false
    @State private var searchQuery = ""
    
    var body: some View {
        VStack(spacing: 20) {
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
                        }) {
                            Label("Clear", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal)
            
            if let data = jsonData {
                ScrollView {
                    JsonView(data: data, searchQuery: searchQuery)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .frame(minWidth: 700, minHeight: 500)
        .padding()
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
    }
    
    private func loadJson(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            jsonData = try JSONSerialization.jsonObject(with: data)
            errorMessage = nil
        } catch let decodingError as DecodingError {
            errorMessage = "Invalid JSON format: \(decodingError.localizedDescription)"
            showingError = true
        } catch {
            errorMessage = "Failed to load JSON: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct JsonView: View {
    let data: Any
    let searchQuery: String
    
    var body: some View {
        Group {
            if let dict = data as? [String: Any] {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(dict.keys.sorted(), id: \.self) { key in
                        DisclosureGroup {
                            JsonView(data: dict[key]!, searchQuery: searchQuery)
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
                        }
                    }
                }
            } else if let array = data as? [Any] {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(array.indices, id: \.self) { index in
                        DisclosureGroup {
                            JsonView(data: array[index], searchQuery: searchQuery)
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
    
    private func stringRepresentation(of data: Any) -> String {
        if data is NSNull {
            return "null"
        }
        return "\(data)"
    }
    
    private func valueColor(for data: Any) -> Color {
        if data is String {
            return .green
        } else if data is Int || data is Double {
            return .blue
        } else if data is Bool {
            return .orange
        } else {
            return .primary
        }
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
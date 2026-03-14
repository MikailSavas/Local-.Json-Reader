import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var jsonData: Any? = nil
    @State private var showingFilePicker = false
    @State private var errorMessage: String? = nil
    @State private var showingError = false
    
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
                    Button(action: {
                        jsonData = nil
                    }) {
                        Label("Clear", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            
            if let data = jsonData {
                ScrollView {
                    JsonView(data: data)
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
    
    var body: some View {
        Group {
            if let dict = data as? [String: Any] {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(dict.keys.sorted(), id: \.self) { key in
                        DisclosureGroup {
                            JsonView(data: dict[key]!)
                                .padding(.leading)
                        } label: {
                            HStack {
                                Text(key)
                                    .font(.system(.body, design: .default))
                                    .fontWeight(.medium)
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
                            JsonView(data: array[index])
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
                Text(stringRepresentation(of: data))
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
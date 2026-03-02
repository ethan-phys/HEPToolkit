//
//  PRLWordCounterView.swift
//  HEPToolkit
//
//  Created by Grok on 27/2/2026.
//  Constructed by Ethan Qiu on 27/02/2026

import SwiftUI
import UniformTypeIdentifiers

// ────────────────────────────────────────────────
// PRL word count logic (your version – solid)
// ────────────────────────────────────────────────
func prlWordCount(from texContent: String) -> (total: Int, textWords: Int, captionWords: Int, eqWords: Int, figureWords: Int, tableWords: Int) {
    var content = texContent

    let removePatterns = [
        #"\\begin\{abstract\}.*?\\end\{abstract\}"#,
        #"\\begin\{acknowledg(?:ements?|ments?)\}.*?\\end\{acknowledg(?:ements?|ments?)\}"#,
        #"\\begin\{thebibliography\}.*?\\end\{thebibliography\}"#,
        #"\\bibliography\{.*?\}"#
    ]
    for pat in removePatterns {
        guard let regex = try? NSRegularExpression(pattern: pat, options: [.dotMatchesLineSeparators, .caseInsensitive]) else { continue }
        content = regex.stringByReplacingMatches(in: content, range: NSRange(location: 0, length: content.utf16.count), withTemplate: "")
    }

    var captionWords = 0
    if let regex = try? NSRegularExpression(pattern: #"\\caption\{(.*?)\}"#, options: [.dotMatchesLineSeparators]) {
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: content.utf16.count))
        for match in matches {
            if let r = Range(match.range(at: 1), in: content) {
                let cap = String(content[r])
                captionWords += cap.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
            }
        }
    }

    var text = content
    let stripPatterns = [
        (#"%.*$"#, NSRegularExpression.Options.anchorsMatchLines),
        (#"\\[a-zA-Z*]+(?:\{[^}]*\})?"#, []),
        (#"\\begin\{[^}]+\}.*?\\end\{[^}]+\}"#, NSRegularExpression.Options.dotMatchesLineSeparators)
    ]
    for (pattern, options) in stripPatterns {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { continue }
        text = regex.stringByReplacingMatches(in: text, range: NSRange(location: 0, length: text.utf16.count), withTemplate: "")
    }

    guard let wordRegex = try? NSRegularExpression(pattern: #"\b\w+\b"#) else { return (0,0,0,0,0,0) }
    let textWords = wordRegex.numberOfMatches(in: text, range: NSRange(location: 0, length: text.utf16.count))

    var inline = 0
    if let r = try? NSRegularExpression(pattern: #"\$[^\$]+\$"#) {
        inline = r.numberOfMatches(in: content, range: NSRange(location: 0, length: content.utf16.count))
    }

    var display = 0
    let dispPatterns = [
        #"\\\[(.*?)\\\]"#,
        #"\\begin\{equation\*?\}.*?\\end\{equation\*?\}"#,
        #"\\begin\{align\*?\}.*?\\end\{align\*?\}"#
    ]
    for p in dispPatterns {
        guard let r = try? NSRegularExpression(pattern: p, options: [.dotMatchesLineSeparators]) else { continue }
        display += r.numberOfMatches(in: content, range: NSRange(location: 0, length: content.utf16.count))
    }
    let eqWords = inline + display * 12

    var figureWords = 0
    let figPatterns = [#"\\begin\{figure\}(?!\*).+?\\end\{figure\}"#, #"\\begin\{figure\*\}.+?\\end\{figure\*\}"#]
    for (i, pat) in figPatterns.enumerated() {
        guard let regex = try? NSRegularExpression(pattern: pat, options: [.dotMatchesLineSeparators]) else { continue }
        let count = regex.numberOfMatches(in: content, range: NSRange(location: 0, length: content.utf16.count))
        figureWords += count * (i == 0 ? 170 : 340)
    }

    var tableWords = 0
    let tablePatterns = [#"\\begin\{table\}(?!\*).+?\\end\{table\}"#, #"\\begin\{table\*\}.+?\\end\{table\*\}"#]
    for (i, pat) in tablePatterns.enumerated() {
        guard let regex = try? NSRegularExpression(pattern: pat, options: [.dotMatchesLineSeparators]) else { continue }
        let count = regex.numberOfMatches(in: content, range: NSRange(location: 0, length: content.utf16.count))
        tableWords += count * (i == 0 ? 170 : 340)
    }

    let total = textWords + captionWords + eqWords + figureWords + tableWords
    return (total, textWords, captionWords, eqWords, figureWords, tableWords)
}

// ────────────────────────────────────────────────
// View
// ────────────────────────────────────────────────
struct PRLWordCounterView: View {
    //@State private var text: String = ""
    //@State private var result: String = "Paste text or load .tex file…"
    //@State private var showingImporter = false
    //@State private var loadedFileName: String? = nil

    @Environment(ToolkitStore.self) private var store
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                
                Button("Load .tex") {
                    store.showingImporter = true
                }
                .buttonStyle(.bordered)

                Button("Clear") {
                    store.text = ""
                    store.result = "Paste text or load .tex file…"
                    store.loadedFileName = nil
                }
                .buttonStyle(.bordered)
                .tint(.red.opacity(0.8))
            }

            if let name = store.loadedFileName {
                Text("Loaded: \(name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: Binding(
                            get: { store.text },
                            set: { store.text = $0 }
                        ))
                .font(.system(.body, design: .monospaced))
                .lineSpacing(4)
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
                .frame(maxHeight: .infinity)

            HStack {
                Button("Count manually") {
                    updateReport()
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }

            ScrollView {
                Text(store.result)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(maxHeight: 220)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(8)
        }
        .padding()
        .fileImporter(
            isPresented: Binding(get: { store.showingImporter }, set: { store.showingImporter = $0 }),
            allowedContentTypes: [.plainText, UTType(filenameExtension: "tex") ?? .plainText],
            allowsMultipleSelection: false
        ) { importResult in
            switch importResult {
            case .success(let urls):
                guard let url = urls.first else {
                    store.result = "No file selected"
                    return
                }

                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }

                    do {
                        store.text = try String(contentsOf: url, encoding: .utf8)
                        store.loadedFileName = url.lastPathComponent
                        updateReport()          // ← auto-report on load
                    } catch {
                        store.loadedFileName = nil
                        store.result = "Read error: \(error.localizedDescription)"
                    }
                } else {
                    store.result = "Access denied to file"
                }

            case .failure(let error):
                store.result = "Import failed: \(error.localizedDescription)"
            }
        }
    }

    private func updateReport() {
        let stats = prlWordCount(from: store.text)
        let status = stats.total <= 3750 ? "UNDER 3750 ✓" : "OVER ✗"

        store.result = """
        Total words: \(stats.total)   \(status)

          - Plain text     : \(stats.textWords)
          - Captions       : \(stats.captionWords)
          - Equations      : \(stats.eqWords)
          - Figures        : \(stats.figureWords)
          - Tables         : \(stats.tableWords)

        PRL Letters limit ≈ 3750 words (excl. title/abstract/refs/acks)
        """
    }
}

#Preview {
    PRLWordCounterView()
}

//
//  Toolkitstore.swift
//  HEPToolkit
//
//  Created by 邱渔骋 on 1/3/2026.
//

import SwiftUI
import Foundation

@MainActor
@Observable
class ToolkitStore {
    // PRL Word Counter persistence
    var text: String = ""
    var loadedFileName: String? = nil
    
    var result: String = "Paste text or load .tex file…"
    var showingImporter = false
    
    // Added for TextEditor selection support
    var textSelection: NSRange? = nil
    
    // Unit Converter persistence (add what you need)
    var valueStr: String = "1.0"
    var factors: [UnitFactor] = []
    var unit_result: String = ""
    var outputPrefixExp: Int = 0
    
    var valueStr_rev: String = "1.0"
    var inputUnitExp_rev: String = "1"
    var factors_rev: [UnitFactor] = []
    var inputPrefixExp_rev: Int = 0
    var unit_result_rev: String = ""
    
    
    // Plot Extractor (future)
    // @Published var plotImage: NSImage? = nil
    // etc.

    init() {
        load()
    }
    
    // Optional: save to disk on change (UserDefaults or file)
    func save() {
        UserDefaults.standard.set(text, forKey: "Text")
        UserDefaults.standard.set(loadedFileName, forKey: "FileName")
        // add others...
    }
    
    func load() {
        text = UserDefaults.standard.string(forKey: "Text") ?? ""
        loadedFileName = UserDefaults.standard.string(forKey: "FileName")
        // ...
    }
}

//
//  HEPToolkitApp.swift
//  HEPToolkit
//
//  Created by 邱渔骋 on 27/2/2026.
//

import SwiftUI

@main
struct HEPToolkitApp: App {
    @State var store = ToolkitStore()
    
    init() {
        store.load()   // restore on launch
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(ToolkitStore())   // or .environment(store) if you have @State var store
        }
        .commands {
            // your existing menu
        }
    }
}

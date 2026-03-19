//
//  HEPToolkitApp.swift
//  HEPToolkit
//
//  Created by 邱渔骋 on 27/2/2026.
//

import SwiftUI

@main
struct HEPToolkitApp: App {
    @State private var store = ToolkitStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .commands {
            // your existing menu
        }
    }
}
